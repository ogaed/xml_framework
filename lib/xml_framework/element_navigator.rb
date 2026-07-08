module XmlFramework
  class ElementNavigator
    DESK_TYPES = %w[
      ACCORDION APPROVALFORM CROSSTAB DASHBOARD DIARY DIARYEDIT
      FILES FILTER FORM FORMVIEW GRID JASPER SEARCH TABLEVIEW
    ].freeze

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def desks
      config[:desks] || []
    end

    def menus
      config[:menus] || []
    end

    def app_config
      config[:app_config] || {}
    end

    def desk(key)
      desks.find { |d| d[:key].to_s == key.to_s }
    end

    # Resolve "965:0" style view keys into desk + component path.
    def resolve_view(view_key)
      return nil if view_key.blank?

      parts = view_key.to_s.split(':')
      desk = desk(parts.first)
      return nil unless desk

      component_path = parts[1..] || []
      component = walk_components(desk[:components], component_path)

      {
        view_key: view_key,
        desk: desk,
        component: component || desk[:components]&.first,
        component_path: component_path
      }
    end

    def find_form(grid_component)
      grid_component[:forms]&.first
    end

    private

    def walk_components(components, path)
      return components&.first if path.blank?

      main = components&.first
      return main unless main

      index = path.first.to_i

      case main[:type]
      when 'accordion'
        panel = main[:panels]&.[](index)
        return panel if path.length == 1
        panel
      when 'grid'
        if path.length == 1
          main[:subgrids]&.[](index) || main[:forms]&.[](index) || main
        else
          sub = main[:subgrids]&.[](index) || main
          walk_nested(sub, path[1..])
        end
      when 'filter'
        main[:tabs]&.[](index) || main
      else
        main
      end
    end

    def walk_nested(component, path)
      return component if path.blank?

      index = path.first.to_i
      case component[:type]
      when 'grid'
        component[:subgrids]&.[](index) || component[:forms]&.[](index) || component
      else
        component
      end
    end
  end
end
