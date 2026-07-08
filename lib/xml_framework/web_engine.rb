require 'securerandom'
require 'fileutils'

module XmlFramework
  class WebEngine
    attr_reader :config, :navigator, :database, :session_store, :access

    def initialize(config, database:, session_store:)
      @config = config
      @database = database
      @session_store = session_store
      @navigator = ElementNavigator.new(config)
      @access = AccessControl.new(session_store)
      @field_renderer_class = FieldRenderer
      @file_uploader = FileUploader.new
    end

    def render_page(view_key, data_item: nil)
      resolved = navigator.resolve_view(view_key)
      return not_found_html unless resolved

      desk = resolved[:desk]
      component = resolved[:component]
      return access_denied_html unless access.can_view?(desk) && access.can_view?(component)

      session_store.view_key = view_key
      session_store.set_data(view_key, data_item) if data_item.present?

      case component[:type]
      when 'dashboard' then render_dashboard(component, desk)
      when 'grid', 'filtergrid' then render_grid(component, view_key, data_item: data_item)
      when 'form', 'filterform' then render_form(component, view_key, data_item: data_item)
      when 'filter' then render_filter(component, view_key)
      when 'accordion' then render_accordion(component, view_key, data_item: data_item)
      when 'jasper' then render_jasper(component, view_key)
      else render_desk_shell(desk, component, view_key)
      end
    end

    def grid_json(view_key, page: 1, per_page: 30, sort_col: nil, sort_dir: 'asc')
      resolved = navigator.resolve_view(view_key)
      return empty_grid_json unless resolved

      component = resolved[:component]
      return empty_grid_json unless %w[grid filtergrid].include?(component[:type])
      return empty_grid_json unless access.can_view?(component)

      link_data = session_store.data_for(view_key)
      extra_where = build_filter_where(component, view_key)
      query = build_query(component, link_data: link_data)
      renderer = field_renderer_for(query)
      json_query = JsonQuery.new(query, component, view_key: view_key, field_renderer: renderer)

      json_query.paginated_response(
        page: page,
        per_page: per_page,
        sort_col: sort_col || session_store.sort_for(view_key)[:column],
        sort_dir: sort_dir || session_store.sort_for(view_key)[:direction],
        extra_where: extra_where
      )
    end

    def save_form(view_key:, params:, data_item: nil, remote_ip: nil, uploaded_files: {})
      resolved = navigator.resolve_view(view_key)
      return error_response('View not found') unless resolved

      grid = resolved[:component]
      form = navigator.find_form(grid) || (%w[form filterform].include?(grid[:type]) ? grid : nil)
      return error_response('Form not found') unless form
      return error_response('Access denied') unless access.can_view?(form)

      merge_uploaded_files!(params, uploaded_files, form[:fields])

      link_data = session_store.data_for(view_key)
      query = build_query(form, link_data: link_data)
      oper = params[:oper] || params['oper'] || (data_item.present? ? 'edit' : 'add')

      begin
        key_value = case oper
                    when 'add', 'insert'
                      query.insert(params, form[:fields], remote_ip: remote_ip,
                        username: session_store.username, user_id: session_store.user_id)
                    when 'edit', 'update'
                      query.update(data_item || params[form[:keyfield]], params, form[:fields],
                        remote_ip: remote_ip, username: session_store.username, user_id: session_store.user_id)
                    when 'del', 'delete'
                      query.delete(data_item || params[form[:keyfield]])
                      data_item
                    else
                      return error_response("Unknown operation: #{oper}")
                    end

        success_response(msg: 'Saved successfully', jump: true, jumpview: view_key, jumplink: key_value)
      rescue StandardError => e
        error_response(e.message)
      end
    end

    def inline_update(view_key:, record_id:, field:, value:)
      resolved = navigator.resolve_view(view_key)
      return error_response('View not found') unless resolved

      component = resolved[:component]
      return error_response('Access denied') unless access.can_view?(component)

      field_def = component[:fields]&.find { |f| f[:field_name] == field }
      return error_response('Field not editable') unless field_def&.dig(:type).to_s == 'editfield'

      query = build_query(component, link_data: session_store.data_for(view_key))
      query.inline_update(record_id, field, value)
      success_response(msg: 'Updated')
    rescue StandardError => e
      error_response(e.message)
    end

    def apply_filter(view_key:, filter_name:, value:)
      session_store.set_filter_param(filter_name, value)
      filter_field = filter_name
      session_store.set_filter(view_key, "#{filter_field} = '#{value.to_s.gsub("'", "''")}'")
      success_response(msg: 'Filter applied', jump: true, jumpview: view_key)
    end

    def execute_action(view_key:, function:, data_item:)
      resolved = navigator.resolve_view(view_key)
      return error_response('View not found') unless resolved

      action = resolved[:component][:actions]&.find { |a| a[:function] == function }
      return error_response('Access denied') if action && !access.can_view?(action)

      sql = "SELECT #{function}($1)"
      database.connection.exec_params(sql, [data_item])
      success_response(msg: "#{function} executed")
    rescue StandardError => e
      error_response(e.message)
    end

    def generate_report(report_file:, params: {})
      reports_dir = report_path
      template = reports_dir.join("#{report_file}.jrxml")
      return error_response("Report template not found: #{report_file}") unless template.exist?

      output_name = "#{report_file}_#{Time.now.to_i}.pdf"
      output_path = Rails.root.join('public', 'reports', output_name)
      FileUtils.mkdir_p(output_path.dirname)

      if system('which', 'jasperstarter', out: File::NULL, err: File::NULL)
        filter_args = params.map { |k, v| "-P#{k}=#{v}" }.join(' ')
        system("jasperstarter pr #{template} -f pdf -o #{output_path.dirname} #{filter_args}")
        return success_response(msg: 'Report generated', jump: false, jumplink: "/reports/#{output_name}")
      end

      # Fallback: return filter params as JSON preview when Jasper CLI is not installed
      success_response(
        msg: "Report queued: #{report_file}",
        jump: false,
        jumplink: nil,
        report: { file: report_file, params: params, template: template.to_s }
      )
    end

    TILE_COLORS = %w[bg-primary bg-success bg-info bg-warning bg-danger bg-secondary].freeze

    def menu_html
      render_sidebar_menu(access.filter_menu_items(navigator.menus))
    end

    private

    def build_query(component, link_data: nil)
      Query.new(database, component, org_id: navigator.app_config[:org], link_data: link_data)
    end

    def field_renderer_for(query, record: nil, view_key: nil)
      @field_renderer_class.new(query: query, record: record, view_key: view_key)
    end

    def build_filter_where(component, view_key)
      parts = []
      parts << session_store.filter_for(view_key) if session_store.filter_for(view_key).present?

      filter_name = component[:filter]
      if filter_name.present?
        val = session_store.filter_param(filter_name)
        field = component[:filterfield] || filter_name
        parts << "#{field} = '#{val.to_s.gsub("'", "''")}'" if val.present?
      end

      parts.compact.join(' AND ').presence
    end

    def merge_uploaded_files!(params, uploaded_files, fields)
      uploaded_files.each do |name, file|
        next unless file.respond_to?(:read)

        field = fields.find { |f| f[:field_name] == name.to_s }
        next unless field && %w[picture file].include?(field[:type].to_s)

        stored = @file_uploader.save(file, field_name: name)
        params[name] = stored if stored
      end
    end

    def render_dashboard(dashboard, desk)
      tiles_html = (dashboard[:tiles] || []).each_with_index.filter_map do |tile, index|
        next unless access.can_view?(tile)

        tile_query = Query.new(database, { table: tile[:table], where: tile[:where], keyfield: 'id' },
                               org_id: navigator.app_config[:org])
        count = tile_query.execute_tile(tile)
        icon = map_icon(tile[:fields]&.first&.dig(:icon))
        color = TILE_COLORS[index % TILE_COLORS.length]
        jump = tile[:jumpview]

        <<~HTML
          <div class="col-sm-6 col-lg-3">
            <div class="card card-sm h-100 dashboard-tile" #{jump ? "onclick=\"jumpToView('#{jump}')\"" : ''}>
              <div class="card-body">
                <div class="d-flex align-items-center gap-3">
                  <span class="symbol symbol-45px symbol-circle #{color}">
                    <span class="symbol-label"><i class="#{icon} fs-2 text-white"></i></span>
                  </span>
                  <div>
                    <div class="tile-value text-gray-900">#{count}</div>
                    <div class="tile-label">#{desk_label(tile[:title])}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        HTML
      end.join

      links_html = (dashboard[:links] || []).map do |link|
        <<~HTML
          <a class="btn btn-outline-primary me-2 mb-2" href="#{link[:url] || "?view=#{link[:view]}"}">
            <i class="#{link[:icon]}"></i> #{link[:title]}
          </a>
        HTML
      end.join

      <<~HTML
        <div class="desk-container">
          <div class="page-heading d-flex flex-column justify-content-center mb-6">
            <h1 class="page-title text-gray-900 fw-bold fs-3 mb-0">#{h(desk[:name])}</h1>
          </div>
          <div class="row g-5 g-xl-8 dashboard-tiles">#{tiles_html}</div>
          #{links_html.present? ? "<div class='mt-4'>#{links_html}</div>" : ''}
        </div>
      HTML
    end

    def render_grid(grid, view_key, data_item: nil)
      form = navigator.find_form(grid)
      form_panel = form && access.can_view?(form) ? render_form_panel(form, view_key, data_item) : ''

      actions_html = (grid[:actions] || []).filter_map do |action|
        next unless access.can_view?(action)

        "<button type='button' class='btn btn-warning me-2 action-fn-btn' data-fnct='#{action[:function]}' data-view='#{view_key}'>#{action[:text] || action[:title]}</button>"
      end.join

      <<~HTML
        <div class="desk-container" data-view-key="#{view_key}">
          <div class="d-flex flex-wrap justify-content-between align-items-center mb-6">
            <h1 class="page-title text-gray-900 fw-bold fs-3 mb-0">#{h(grid[:name])}</h1>
            <div class="d-flex gap-2">
              #{actions_html}
              #{form ? "<button type='button' class='btn btn-sm btn-primary' onclick='showFormPanel()'><i class='ti ti-plus me-1'></i>New</button>" : ''}
            </div>
          </div>
          <div class="card card-flush mb-5">
            <div class="card-body p-0">
              <div id="jqlist" class="ag-theme-alpine xml-grid" style="height: 500px; width: 100%;"
                   data-view="#{view_key}" data-keyfield="#{grid[:keyfield]}"></div>
            </div>
          </div>
          <div id="xml-form-panel" class="xml-form-panel #{data_item.present? ? '' : 'd-none'}">
            #{form_panel}
          </div>
        </div>
      HTML
    end

    def render_form_panel(form, view_key, data_item)
      link_data = session_store.data_for(view_key)
      query = build_query(form, link_data: link_data)
      record = data_item.present? ? query.fetch_record(data_item) : {}
      renderer = field_renderer_for(query, record: record, view_key: view_key)

      fields_html = (form[:fields] || []).map { |field| renderer.render_form_field(field) }.join
      oper = data_item.present? ? 'edit' : 'add'
      has_file = (form[:fields] || []).any? { |f| %w[picture file].include?(f[:type].to_s) }

      <<~HTML
        <div class="card mt-3">
          <div class="card-header d-flex justify-content-between">
            <strong>#{h(form[:name])}</strong>
            <button type="button" class="btn-close" onclick="hideFormPanel()"></button>
          </div>
          <div class="card-body">
            <form id="xml-data-form" class="xml-data-form" data-view="#{view_key}" data-oper="#{oper}"
                  data-key="#{h(data_item)}" #{has_file ? "enctype='multipart/form-data'" : ''}>
              #{fields_html}
              <div class="mt-3">
                <button type="submit" class="btn btn-success">Save</button>
                #{data_item.present? ? "<button type='button' class='btn btn-danger ms-2' onclick='deleteRecord()'>Delete</button>" : ''}
              </div>
            </form>
          </div>
        </div>
      HTML
    end

    def render_form(form, view_key, data_item: nil)
      render_form_panel(form, view_key, data_item)
    end

    def render_filter(filter, view_key)
      Views::FilterRenderer.new(self, database: database, session_store: session_store, navigator: navigator).render(filter, view_key)
    end

    def render_accordion(accordion, view_key, data_item: nil)
      Views::AccordionRenderer.new(self).render(accordion, view_key, data_item: data_item)
    end

    def render_jasper(jasper, view_key)
      Views::JasperRenderer.new(self).render(jasper, view_key)
    end

    def render_desk_shell(desk, component, view_key)
      <<~HTML
        <div class="desk-container">
          <h2>#{h(desk[:name])}</h2>
          <div class="alert alert-info">View type #{component&.dig(:type)} is not yet implemented.</div>
        </div>
      HTML
    end

    def render_sidebar_menu(items)
      items.map { |item| render_sidebar_item(item) }.join
    end

    def render_sidebar_item(item)
      if item[:children]&.any?
        <<~HTML
          <div data-kt-menu-trigger="click" class="menu-item menu-accordion">
            <span class="menu-link">
              <span class="menu-icon">#{sidebar_icon(item[:icon])}</span>
              <span class="menu-title">#{h(item[:name])}</span>
              <span class="menu-arrow"></span>
            </span>
            <div class="menu-sub menu-sub-accordion">
              #{render_sidebar_menu(item[:children])}
            </div>
          </div>
        HTML
      else
        key = item[:key]
        <<~HTML
          <div class="menu-item">
            <a class="menu-link" href="/xml_app/#{key}">
              <span class="menu-icon">#{sidebar_icon(item[:icon])}</span>
              <span class="menu-title">#{h(item[:name])}</span>
            </a>
          </div>
        HTML
      end
    end

    def sidebar_icon(icon)
      "<i class=\"#{map_icon(icon)}\"></i>"
    end

    def map_icon(icon)
      return 'ti ti-chart-pie' if icon.blank?
      return icon if icon.start_with?('ti ', 'ki-duotone', 'ki-outline')

      case icon
      when /users?/ then 'ti ti-users'
      when /graduate|user-plus/ then 'ti ti-user-plus'
      when /file-check|check/ then 'ti ti-file-check'
      when /file-excel|excel/ then 'ti ti-file-spreadsheet'
      when /exclamation|warning/ then 'ti ti-alert-triangle'
      when /exchange/ then 'ti ti-arrows-exchange'
      when /chart|pie/ then 'ti ti-chart-pie'
      else 'ti ti-point'
      end
    end

    def render_menu_items(items, depth = 0)
      render_sidebar_menu(items)
    end

    def report_path
      if defined?(Rails) && Rails.respond_to?(:root)
        Rails.root.join('reports')
      else
        Pathname.new(Dir.pwd).join('reports')
      end
    end

    def empty_grid_json
      { rows: [], records: 0, page: 1, total: 0, columnDefs: [] }
    end

    def success_response(msg:, jump: false, jumpview: nil, jumplink: nil, report: nil)
      { success: true, msg: msg, jump: jump, jumpview: jumpview, jumplink: jumplink, report: report }.compact
    end

    def error_response(msg)
      { success: false, msg: msg }
    end

    def not_found_html
      "<div class='alert alert-danger'>Page not found</div>"
    end

    def access_denied_html
      "<div class='alert alert-danger'><i class='fa fa-lock'></i> You do not have access to this page.</div>"
    end

    def h(value)
      ERB::Util.html_escape(value.to_s)
    end

    def desk_label(title)
      h(title)
    end
  end
end
