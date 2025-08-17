module XmlFramework
  module Components
    class Base
      attr_reader :attributes, :content

      def initialize(attributes = {}, content = nil)
        @attributes = attributes
        @content = content
      end

      def render
        raise NotImplementedError, "Subclasses must implement render method"
      end

      protected

      def build_html_attributes(attrs = {})
        merged_attrs = @attributes.merge(attrs)
        merged_attrs.map { |k, v| "#{k}='#{v}'" }.join(' ')
      end
    end

    class Grid < Base
      def render
        <<~HTML
          <div class="xml-grid" #{build_html_attributes}>
            <table class="table table-striped">
              #{render_header}
              #{render_body}
            </table>
          </div>
        HTML
      end

      private

      def render_header
        return '' unless @attributes[:fields]
        
        headers = @attributes[:fields].map do |field|
          "<th style='width: #{field[:width]}px;'>#{field[:title]}</th>"
        end.join
        
        "<thead><tr>#{headers}</tr></thead>"
      end

      def render_body
        return '<tbody></tbody>' unless @attributes[:data]
        
        rows = @attributes[:data].map do |row|
          cells = @attributes[:fields].map do |field|
            value = row[field[:field_name].to_sym] || row[field[:field_name]]
            "<td>#{value}</td>"
          end.join
          "<tr>#{cells}</tr>"
        end.join
        
        "<tbody>#{rows}</tbody>"
      end
    end

    class Form < Base
      def render
        <<~HTML
          <div class="xml-form" #{build_html_attributes}>
            <form>
              #{render_fields}
            </form>
          </div>
        HTML
      end

      private

      def render_fields
        return '' unless @attributes[:fields]
        
        @attributes[:fields].map do |field|
          render_field(field)
        end.join
      end

      def render_field(field)
        case field[:type]
        when 'textfield'
          render_textfield(field)
        when 'textarea'
          render_textarea(field)
        when 'combobox', 'combolist'
          render_select(field)
        when 'checkbox'
          render_checkbox(field)
        when 'textdate'
          render_date(field)
        else
          "<div>Unknown field type: #{field[:type]}</div>"
        end
      end

      def render_textfield(field)
        <<~HTML
          <div class="form-group">
            <label for="#{field[:field_name]}">#{field[:title]}</label>
            <input type="text" 
                   id="#{field[:field_name]}" 
                   name="#{field[:field_name]}" 
                   class="form-control"
                   #{field[:required] ? 'required' : ''} />
          </div>
        HTML
      end

      def render_textarea(field)
        <<~HTML
          <div class="form-group">
            <label for="#{field[:field_name]}">#{field[:title]}</label>
            <textarea id="#{field[:field_name]}" 
                      name="#{field[:field_name]}" 
                      class="form-control"></textarea>
          </div>
        HTML
      end

      def render_select(field)
        options = if field[:options]
          field[:options].map { |opt| "<option value='#{opt}'>#{opt}</option>" }.join
        else
          "<!-- Options loaded from #{field[:lptable]} -->"
        end

        <<~HTML
          <div class="form-group">
            <label for="#{field[:field_name]}">#{field[:title]}</label>
            <select id="#{field[:field_name]}" 
                    name="#{field[:field_name]}" 
                    class="form-control">
              #{options}
            </select>
          </div>
        HTML
      end

      def render_checkbox(field)
        <<~HTML
          <div class="form-group form-check">
            <input type="checkbox" 
                   id="#{field[:field_name]}" 
                   name="#{field[:field_name]}" 
                   class="form-check-input" />
            <label class="form-check-label" for="#{field[:field_name]}">
              #{field[:title]}
            </label>
          </div>
        HTML
      end

      def render_date(field)
        <<~HTML
          <div class="form-group">
            <label for="#{field[:field_name]}">#{field[:title]}</label>
            <input type="date" 
                   id="#{field[:field_name]}" 
                   name="#{field[:field_name]}" 
                   class="form-control" />
          </div>
        HTML
      end
    end

    class Dashboard < Base
      def render
        <<~HTML
          <div class="xml-dashboard" #{build_html_attributes}>
            <h3>#{@attributes[:name]}</h3>
            <div class="dashboard-tiles">
              #{render_tiles}
            </div>
          </div>
        HTML
      end

      private

      def render_tiles
        return '' unless @attributes[:tiles]
        
        @attributes[:tiles].map do |tile|
          render_tile(tile)
        end.join
      end

      def render_tile(tile)
        icon_class = tile[:fields]&.first&.dig(:icon) || 'fa fa-info'
        
        <<~HTML
          <div class="dashboard-tile" onclick="jumpToView('#{tile[:jumpview]}')">
            <div class="tile-header">
              <i class="#{icon_class}"></i>
              <span class="tile-title">#{tile[:title]}</span>
            </div>
            <div class="tile-content">
              <span class="tile-number">#{tile[:data] || 0}</span>
            </div>
          </div>
        HTML
      end
    end
  end
end
