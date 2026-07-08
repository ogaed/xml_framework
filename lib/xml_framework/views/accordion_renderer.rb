module XmlFramework
  module Views
    class AccordionRenderer
      def initialize(engine)
        @engine = engine
      end

      def render(accordion, view_key, data_item: nil)
        panels_html = accordion[:panels].each_with_index.map do |panel, index|
          render_panel(panel, index, view_key, data_item: data_item)
        end.join

        <<~HTML
          <div class="desk-container accordion-view" data-view-key="#{view_key}">
            <h2>#{@engine.send(:h, accordion[:name] || 'Details')}</h2>
            <div class="accordion" id="xml-accordion-#{view_key.tr(':', '-')}">
              #{panels_html}
            </div>
          </div>
        HTML
      end

      private

      def render_panel(panel, index, view_key, data_item: nil)
        expanded = panel[:collapse].to_s.include?('show') || index.zero?
        panel_id = "collapse_#{view_key.tr(':', '_')}_#{index}"

        body = case panel[:type]
               when 'form'
                 @engine.send(:render_form_panel, panel, view_key, data_item)
               when 'grid'
                 render_sub_grid(panel, view_key, index)
               else
                 "<div class='alert alert-warning'>Unknown panel type</div>"
               end

        <<~HTML
          <div class="accordion-item">
            <h2 class="accordion-header">
              <button class="accordion-button#{expanded ? '' : ' collapsed'}" type="button"
                      data-bs-toggle="collapse" data-bs-target="##{panel_id}">
                #{@engine.send(:h, panel[:name] || panel[:type].to_s.capitalize)}
              </button>
            </h2>
            <div id="#{panel_id}" class="accordion-collapse collapse#{expanded ? ' show' : ''}">
              <div class="accordion-body">#{body}</div>
            </div>
          </div>
        HTML
      end

      def render_sub_grid(grid, view_key, index)
        sub_view = "#{view_key}:#{index}"
        <<~HTML
          <div id="sub_grid_#{index}" class="ag-theme-alpine xml-grid sub-grid"
               style="height: 300px;" data-view="#{sub_view}" data-keyfield="#{grid[:keyfield]}"></div>
        HTML
      end
    end
  end
end
