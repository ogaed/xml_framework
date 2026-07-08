module XmlFramework
  class FieldRenderer
    include ERB::Util

    def initialize(query: nil, record: nil, view_key: nil, form_readonly: false)
      @query = query
      @record = record || {}
      @view_key = view_key
      @form_readonly = form_readonly
    end

    def render_form_field(field)
      value = field_value(field)
      type = field[:type].to_s

      case type
      when 'textfield' then render_textfield(field, value)
      when 'textarea' then render_textarea(field, value)
      when 'editor' then render_editor(field, value)
      when 'password' then render_password(field)
      when 'combobox', 'gridbox' then render_combobox(field, value)
      when 'combolist' then render_combolist(field, value)
      when 'multiselect' then render_multiselect(field, value)
      when 'checkbox' then render_checkbox(field, value)
      when 'textdate' then render_textdate(field, value)
      when 'textdecimal', 'textnumber' then render_decimal(field, value)
      when 'texttimestamp' then render_timestamp(field, value)
      when 'spintime', 'texttime' then render_time(field, value)
      when 'picture', 'file' then render_file(field, value)
      when 'barcode' then render_textfield(field, value)
      when 'html' then field[:html].to_s
      when 'default', 'userfield', 'username', 'remoteip', 'function', 'levelkey'
        "<input type='hidden' name='#{field[:field_name]}' value='#{h(value)}' />"
      else
        "<div class='alert alert-warning'>Unknown field: #{h(type)}</div>"
      end
    end

    def render_grid_cell(field, value, row: {}, key_value: nil)
      type = field[:type].to_s

      case type
      when 'checkbox'
        checked = %w[true t 1 yes].include?(value.to_s.downcase)
        "<span class='badge #{checked ? 'bg-success' : 'bg-secondary'}'>#{checked ? 'Yes' : 'No'}</span>"
      when 'textdate'
        value.present? ? Date.parse(value.to_s).strftime('%Y-%m-%d') : ''
      when 'textdecimal', 'textnumber'
        "<span class='text-end d-block'>#{h(value)}</span>"
      when 'browser'
        "<a href='#' class='browser-link' data-action='#{h(field[:action])}' data-value='#{h(value)}'>#{h(field[:title])}</a>"
      when 'weblink', 'textlink'
        url = interpolate_url(field[:url] || value.to_s, row)
        label = field[:title].presence || value
        "<a href='#{h(url)}' target='_blank' rel='noopener'>#{h(label)}</a>"
      when 'picture'
        render_picture_cell(field, value)
      when 'editfield'
        h(value)
      when 'button'
        "<button type='button' class='btn btn-sm btn-outline-primary grid-btn' data-fn='#{h(field[:js_function])}'>#{h(field[:title] || value)}</button>"
      when 'action'
        "<button type='button' class='btn btn-sm btn-primary action-btn' data-action='#{h(value)}'>#{h(field[:title] || 'Action')}</button>"
      when 'search'
        "<button type='button' class='btn btn-sm btn-secondary search-btn' data-key='#{h(key_value)}' data-value='#{h(value)}'>Select</button>"
      when 'rowcounter'
        h(value)
      else
        h(value)
      end
    end

    def raw_grid_value(field, value)
      case field[:type].to_s
      when 'checkbox'
        %w[true t 1 yes].include?(value.to_s.downcase)
      when 'textdate'
        value.present? ? Date.parse(value.to_s).strftime('%Y-%m-%d') : nil
      when 'textdecimal', 'textnumber'
        value.to_s.delete(',').presence
      else
        value
      end
    rescue StandardError
      value
    end

    private

    def interpolate_url(url, row)
      url.to_s.gsub(/\{(\w+)\}/) { row[$1] || row[$1.to_sym] || '' }
    end

    def render_picture_cell(field, value)
      return '' if value.blank?

      src = if field[:pictures].present?
              "#{field[:pictures]}?access=#{field[:access]}&picture=#{h(value)}"
            else
              "/uploads/#{h(value)}"
            end
      "<img src='#{src}' alt='' class='grid-picture' style='max-height:48px;border-radius:4px' />"
    end

    def field_value(field)
      @record[field[:field_name]] || @record[field[:field_name].to_s]
    end

    def readonly_attr(field)
      'readonly' if @form_readonly || field[:readonly]
    end

    def disabled_attr(field)
      'disabled' if field[:enabled] == false
    end

    def required_attr(field)
      'required' if field[:required]
    end

    def render_textfield(field, value)
      input_type = field[:input_type] || 'text'
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="#{input_type}" name="#{field[:field_name]}" class="form-control"
                 value="#{h(value)}" #{required_attr(field)} #{readonly_attr(field)} #{disabled_attr(field)}
                 placeholder="#{h(field[:placeholder])}" />
        </div>
      HTML
    end

    def render_textarea(field, value)
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <textarea name="#{field[:field_name]}" class="form-control" rows="#{field[:rows] || 4}"
                    #{required_attr(field)} #{readonly_attr(field)} #{disabled_attr(field)}>#{h(value)}</textarea>
        </div>
      HTML
    end

    def render_editor(field, value)
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <textarea name="#{field[:field_name]}" class="form-control xml-editor" rows="8">#{h(value)}</textarea>
        </div>
      HTML
    end

    def render_password(field)
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="password" name="#{field[:field_name]}" class="form-control" #{required_attr(field)} />
        </div>
      HTML
    end

    def render_combobox(field, value)
      options = @query&.combobox_options(field) || []
      opts_html = options.map do |row|
        key = row.values.first
        label = row.values.length > 1 ? row.values[1] : key
        selected = key.to_s == value.to_s ? 'selected' : ''
        "<option value='#{h(key)}' #{selected}>#{h(label)}</option>"
      end.join

      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <select name="#{field[:field_name]}" class="form-select" #{required_attr(field)} #{disabled_attr(field)}>
            <option value=""></option>
            #{opts_html}
          </select>
        </div>
      HTML
    end

    def render_combolist(field, value)
      opts = (field[:options] || []).map do |opt|
        key = opt.is_a?(Hash) ? opt[:key] : opt
        label = opt.is_a?(Hash) ? opt[:label] : opt
        selected = key.to_s == value.to_s ? 'selected' : ''
        "<option value='#{h(key)}' #{selected}>#{h(label)}</option>"
      end.join

      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <select name="#{field[:field_name]}" class="form-select" #{required_attr(field)}>
            <option value=""></option>
            #{opts}
          </select>
        </div>
      HTML
    end

    def render_multiselect(field, value)
      selected = value.to_s.split(',').map(&:strip)
      options = @query&.combobox_options(field) || selected.map { |v| { 'v' => v } }
      opts = options.map do |row|
        key = row.values.first
        label = row.values.length > 1 ? row.values[1] : key
        sel = selected.include?(key.to_s) ? 'selected' : ''
        "<option value='#{h(key)}' #{sel}>#{h(label)}</option>"
      end.join

      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <select name="#{field[:field_name]}" class="form-select" multiple #{required_attr(field)}>
            #{opts}
          </select>
        </div>
      HTML
    end

    def render_checkbox(field, value)
      checked = %w[true t 1 yes].include?(value.to_s.downcase) ? 'checked' : ''
      <<~HTML
        <div class="mb-3 form-check xml-field" style="#{position_style(field)}">
          <input type="checkbox" name="#{field[:field_name]}" value="1" class="form-check-input" #{checked} #{disabled_attr(field)} />
          <label class="form-check-label">#{h(field[:title])}</label>
        </div>
      HTML
    end

    def render_textdate(field, value)
      formatted = value.present? ? Date.parse(value.to_s).strftime('%Y-%m-%d') : ''
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="date" name="#{field[:field_name]}" class="form-control" value="#{h(formatted)}"
                 #{required_attr(field)} #{readonly_attr(field)} />
        </div>
      HTML
    end

    def render_decimal(field, value)
      render_textfield(field.merge(input_type: 'text'), value)
    end

    def render_timestamp(field, value)
      formatted = value.present? ? Time.parse(value.to_s).strftime('%Y-%m-%dT%H:%M') : ''
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="datetime-local" name="#{field[:field_name]}" class="form-control" value="#{h(formatted)}" />
        </div>
      HTML
    end

    def render_time(field, value)
      formatted = value.to_s[0, 5]
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="time" name="#{field[:field_name]}" class="form-control" value="#{h(formatted)}" />
        </div>
      HTML
    end

    def render_file(field, value)
      <<~HTML
        <div class="mb-3 xml-field" style="#{position_style(field)}">
          #{label_for(field)}
          <input type="file" name="#{field[:field_name]}" class="form-control" />
          #{value.present? ? "<small class='text-muted'>Current: #{h(value)}</small>" : ''}
        </div>
      HTML
    end

    def label_for(field)
      return '' if field[:title].blank?

      req = field[:required] ? " <span class='text-danger'>*</span>" : ''
      "<label class='form-label'>#{h(field[:title])}#{req}</label>"
    end

    def position_style(field)
      return '' unless field[:x] || field[:y]

      "position:absolute;left:#{field[:x] || 0}px;top:#{field[:y] || 0}px;width:#{field[:width] || 150}px;"
    end
  end
end
