module XmlFramework
  class Renderer
    def render_desk(desk, database)
      case desk[:components].first[:type]
      when 'dashboard'
        render_dashboard(desk[:components].first, database)
      when 'grid'
        render_grid(desk[:components].first, database)
      else
        render_generic_desk(desk, database)
      end
    end

    def render_desk_view(desk)
      <<~ERB
        <div class="desk-container" style="width: #{desk[:width]}px; height: #{desk[:height]}px;">
          <h2><%= "#{desk[:name]}" %></h2>
          
          <% @desk_data[:components].each do |component| %>
            <%= render_component(component) %>
          <% end %>
        </div>
      ERB
    end

    private

    def render_dashboard(dashboard, database)
      html = <<~HTML
        <div class="dashboard" style="width: #{dashboard[:width]}px;">
          <h3>#{dashboard[:name]}</h3>
          <div class="tiles-container">
      HTML

      dashboard[:tiles].each do |tile|
        html += render_tile(tile, database)
      end

      html += <<~HTML
          </div>
        </div>
      HTML
    end

    def render_tile(tile, database)
      data = database.execute_tile_query(tile)
      icon_class = tile[:fields].first[:icon] if tile[:fields].any?
      
      <<~HTML
        <div class="tile" onclick="jumpToView('#{tile[:jumpview]}')">
          <div class="tile-header">
            <i class="#{icon_class}"></i>
            <span class="tile-title">#{tile[:title]}</span>
          </div>
          <div class="tile-content">
            <span class="tile-number">#{data}</span>
          </div>
        </div>
      HTML
    end

    def render_grid(grid, database)
      data = database.execute_grid_query(grid)
      
      html = <<~HTML
        <div class="grid-container">
          <h3>#{grid[:name]}</h3>
          <table class="data-grid">
            <thead>
              <tr>
      HTML

      grid[:fields].each do |field|
        html += "<th style='width: #{field[:width]}px;'>#{field[:title]}</th>"
      end

      html += <<~HTML
              </tr>
            </thead>
            <tbody>
      HTML

      data.each do |row|
        html += "<tr>"
        grid[:fields].each do |field|
          value = row[field[:field_name]]
          html += render_field_value(field, value)
        end
        html += "</tr>"
      end

      html += <<~HTML
            </tbody>
          </table>
        </div>
      HTML
    end

    def render_field_value(field, value)
      case field[:type]
      when 'checkbox'
        checked = value ? 'checked' : ''
        "<td><input type='checkbox' #{checked} disabled></td>"
      when 'textdate'
        formatted_date = value ? Date.parse(value.to_s).strftime('%Y-%m-%d') : ''
        "<td>#{formatted_date}</td>"
      when 'browser'
        "<td><a href='#' onclick=\"openBrowser('#{field[:action]}', '#{value}')\">#{field[:title]}</a></td>"
      else
        "<td>#{value}</td>"
      end
    end

    def render_form(form)
      html = <<~HTML
        <div class="form-container" style="width: #{form[:width]}px; height: #{form[:height]}px;">
          <h4>#{form[:name]}</h4>
          <form>
      HTML

      form[:fields].each do |field|
        html += render_form_field(field)
      end

      html += <<~HTML
          </form>
        </div>
      HTML
    end

    def render_form_field(field)
      style = "position: absolute; left: #{field[:x]}px; top: #{field[:y]}px; width: #{field[:width]}px; height: #{field[:height]}px;"
      
      case field[:type]
      when 'textfield'
        <<~HTML
          <div style="#{style}">
            <label>#{field[:title]}</label>
            <input type="text" name="#{field[:field_name]}" />
          </div>
        HTML
      when 'textarea'
        <<~HTML
          <div style="#{style}">
            <label>#{field[:title]}</label>
            <textarea name="#{field[:field_name]}"></textarea>
          </div>
        HTML
      when 'combobox'
        <<~HTML
          <div style="#{style}">
            <label>#{field[:title]}</label>
            <select name="#{field[:field_name]}">
              <!-- Options loaded from #{field[:lptable]} -->
            </select>
          </div>
        HTML
      when 'combolist'
        options = field[:options].map { |opt| "<option value='#{opt}'>#{opt}</option>" }.join
        <<~HTML
          <div style="#{style}">
            <label>#{field[:title]}</label>
            <select name="#{field[:field_name]}">
              #{options}
            </select>
          </div>
        HTML
      when 'checkbox'
        <<~HTML
          <div style="#{style}">
            <label>
              <input type="checkbox" name="#{field[:field_name]}" />
              #{field[:title]}
            </label>
          </div>
        HTML
      when 'textdate'
        <<~HTML
          <div style="#{style}">
            <label>#{field[:title]}</label>
            <input type="date" name="#{field[:field_name]}" />
          </div>
        HTML
      else
        "<div style='#{style}'>Unknown field type: #{field[:type]}</div>"
      end
    end

    def render_generic_desk(desk, database)
      html = "<div class='desk-container'><h2>#{desk[:name]}</h2>"
      
      desk[:components].each do |component|
        case component[:type]
        when 'grid'
          html += render_grid(component, database)
        when 'dashboard'
          html += render_dashboard(component, database)
        when 'jasper'
          html += render_jasper_report(component)
        end
      end
      
      html += "</div>"
    end

    def render_jasper_report(jasper)
      <<~HTML
        <div class="jasper-report">
          <h4>#{jasper[:name]}</h4>
          <button onclick="generateReport('#{jasper[:reportfile]}')">Generate Report</button>
        </div>
      HTML
    end
  end
end
