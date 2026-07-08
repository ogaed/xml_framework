module XmlFramework
  module Views
    class FilterRenderer
      def initialize(engine, database:, session_store:, navigator:)
        @engine = engine
        @database = database
        @session_store = session_store
        @navigator = navigator
      end

      def render(filter, view_key)
        tabs = filter[:tabs] || []
        return empty_filter(view_key) if tabs.empty?

        nav_items = tabs.each_with_index.map do |tab, i|
          active = i.zero? ? 'active' : ''
          tab_id = tab_id_for(tab)
          <<~HTML
            <li class="nav-item">
              <a class="nav-link #{active}" data-bs-toggle="tab" href="##{tab_id}">#{h(tab[:name])}</a>
            </li>
          HTML
        end.join

        panes = tabs.each_with_index.map do |tab, i|
          active = i.zero? ? 'show active' : ''
          tab_id = tab_id_for(tab)
          <<~HTML
            <div class="tab-pane fade #{active}" id="#{tab_id}">
              #{render_tab(tab, view_key)}
            </div>
          HTML
        end.join

        <<~HTML
          <div class="desk-container filter-view" data-view-key="#{view_key}">
            <h2>#{h(filter[:name] || 'Filter')}</h2>
            <ul class="nav nav-tabs mb-3">#{nav_items}</ul>
            <div class="tab-content">#{panes}</div>
          </div>
        HTML
      end

      private

      def render_tab(tab, view_key)
        case tab[:type]
        when 'filtergrid', 'grid'
          render_filter_grid(tab, view_key)
        when 'drilldown'
          render_drilldown(tab)
        when 'filterform', 'form'
          render_filter_form(tab, view_key)
        when 'jasper'
          render_jasper_tab(tab, view_key)
        else
          "<div class='alert alert-info'>Tab type #{tab[:type]} not supported</div>"
        end
      end

      def render_filter_grid(grid, view_key)
        filter_name = grid[:filter] || 'filterid'
        <<~HTML
          <div id="jqlist" class="ag-theme-alpine xml-grid" style="height: 450px;"
               data-view="#{view_key}" data-keyfield="#{grid[:keyfield]}"
               data-filter="#{filter_name}"></div>
        HTML
      end

      def render_drilldown(drilldown, parent_key: nil)
        filter_name = drilldown[:filter] || 'filterid'
        items = drill_items(drilldown, parent_key)

        children_html = (drilldown[:children] || []).map do |child|
          render_drilldown(child, parent_key: nil)
        end.join

        <<~HTML
          <input type="hidden" name="#{filter_name}" id="#{filter_name}" value="0" />
          <div class="drilldown-tree border rounded p-3" data-filter="#{filter_name}">
            <ul class="list-unstyled drilldown-list">
              #{items}
            </ul>
            #{children_html}
          </div>
        HTML
      end

      def drill_items(drilldown, parent_key)
        query = XmlFramework::Query.new(
          @database,
          {
            table: drilldown[:table],
            keyfield: drilldown[:keyfield],
            where: drilldown[:where],
            noorg: drilldown[:noorg]
          },
          org_id: @navigator.app_config[:org]
        )

        extra = if parent_key.present? && drilldown[:wherefield].present?
                  "#{drilldown[:wherefield]} = '#{sanitize(parent_key)}'"
                end

        rows = query.fetch_rows(page: 1, per_page: 500, extra_where: extra)
        filter_name = drilldown[:filter] || 'filterid'

        rows.map do |row|
          key = row[drilldown[:keyfield]]
          label = row[drilldown[:listfield]] || key
          <<~HTML
            <li>
              <a href="#" class="drilldown-link" data-filter="#{filter_name}" data-value="#{h(key)}">#{h(label)}</a>
            </li>
          HTML
        end.join
      rescue StandardError
        '<li class="text-muted">No drilldown data</li>'
      end

      def render_filter_form(form, view_key)
        @engine.send(:render_form_panel, form, view_key, nil)
      end

      def render_jasper_tab(jasper, view_key)
        XmlFramework::Views::JasperRenderer.new(@engine).render(jasper, view_key)
      end

      def empty_filter(view_key)
        "<div class='alert alert-warning'>Filter view #{view_key} has no tabs defined</div>"
      end

      def tab_id_for(tab)
        "tab_#{tab[:name].to_s.parameterize.presence || tab[:type]}"
      end

      def h(v)
        ERB::Util.html_escape(v.to_s)
      end

      def sanitize(v)
        v.to_s.gsub("'", "''")
      end
    end
  end
end
