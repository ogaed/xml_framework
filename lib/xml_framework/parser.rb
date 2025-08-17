require 'nokogiri'

module XmlFramework
  class Parser
    def parse_file(file_path)
      xml_content = File.read(file_path)
      parse_xml(xml_content)
    end

    def parse_xml(xml_content)
      doc = Nokogiri::XML(xml_content)
      app_node = doc.at_xpath('//APP')
      
      {
        app_config: parse_app_config(app_node),
        menus: parse_menus(doc),
        desks: parse_desks(doc)
      }
    end

    private

    def parse_app_config(app_node)
      {
        password: app_node['password'],
        org: app_node['org'],
        name: app_node['name']
      }
    end

    def parse_menus(doc)
      menu_nodes = doc.xpath('//MENU')
      menu_nodes.map { |node| parse_menu_node(node) }
    end

    def parse_menu_node(node)
      {
        name: node['name'],
        role: node['role'],
        icon: node['icon'],
        key: node.text.strip,
        children: node.xpath('./MENU').map { |child| parse_menu_node(child) }
      }
    end

    def parse_desks(doc)
      desk_nodes = doc.xpath('//DESK')
      desk_nodes.map { |node| parse_desk_node(node) }
    end

    def parse_desk_node(node)
      {
        name: node['name'],
        key: node['key'],
        width: node['w'],
        height: node['h'],
        type: node['type'],
        access: node['access'],
        components: parse_desk_components(node)
      }
    end

    def parse_desk_components(desk_node)
      components = []
      
      # Parse DASHBOARD components
      desk_node.xpath('./DASHBOARD').each do |dashboard|
        components << parse_dashboard(dashboard)
      end
      
      # Parse GRID components
      desk_node.xpath('./GRID').each do |grid|
        components << parse_grid(grid)
      end
      
      # Parse JASPER reports
      desk_node.xpath('./JASPER').each do |jasper|
        components << parse_jasper(jasper)
      end
      
      # Parse FILTER components
      desk_node.xpath('./FILTER').each do |filter|
        components << parse_filter(filter)
      end
      
      components
    end

    def parse_dashboard(dashboard_node)
      {
        type: 'dashboard',
        name: dashboard_node['name'],
        width: dashboard_node['w'],
        refresh: dashboard_node['refresh'],
        tiles: parse_tiles(dashboard_node)
      }
    end

    def parse_tiles(dashboard_node)
      dashboard_node.xpath('./TILE').map do |tile|
        {
          name: tile['name'],
          access: tile['access'],
          display: tile['display'],
          title: tile['title'],
          table: tile['table'],
          where: tile['where'],
          groupby: tile['groupby'],
          jumpview: tile['jumpview'],
          fields: parse_tile_fields(tile)
        }
      end
    end

    def parse_tile_fields(tile_node)
      tile_node.xpath('./TEXTFIELD').map do |field|
        {
          width: field['w'],
          icon: field['icon'],
          function: field['fnct'],
          title: field['title'],
          field_name: field.text.strip
        }
      end
    end

    def parse_grid(grid_node)
      {
        type: 'grid',
        name: grid_node['name'],
        keyfield: grid_node['keyfield'],
        table: grid_node['table'],
        where: grid_node['where'],
        orderby: grid_node['orderby'],
        limit: grid_node['limit'],
        noorg: grid_node['noorg'],
        linkfield: grid_node['linkfield'],
        fields: parse_grid_fields(grid_node),
        forms: parse_forms(grid_node),
        actions: parse_actions(grid_node),
        subgrids: parse_subgrids(grid_node)
      }
    end

    def parse_grid_fields(grid_node)
      fields = []
      
      grid_node.xpath('./TEXTFIELD').each do |field|
        fields << parse_textfield(field)
      end
      
      grid_node.xpath('./CHECKBOX').each do |field|
        fields << parse_checkbox(field)
      end
      
      grid_node.xpath('./TEXTDATE').each do |field|
        fields << parse_textdate(field)
      end
      
      grid_node.xpath('./TEXTDECIMAL').each do |field|
        fields << parse_textdecimal(field)
      end
      
      grid_node.xpath('./BROWSER').each do |field|
        fields << parse_browser(field)
      end
      
      fields
    end

    def parse_textfield(field_node)
      {
        type: 'textfield',
        width: field_node['w'],
        title: field_node['title'],
        format: field_node['format'],
        field_name: field_node.text.strip
      }
    end

    def parse_checkbox(field_node)
      {
        type: 'checkbox',
        width: field_node['w'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_textdate(field_node)
      {
        type: 'textdate',
        width: field_node['w'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_textdecimal(field_node)
      {
        type: 'textdecimal',
        width: field_node['w'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_browser(field_node)
      {
        type: 'browser',
        width: field_node['w'],
        title: field_node['title'],
        action: field_node['action'],
        linkfield: field_node['linkfield'],
        blankpage: field_node['blankpage'],
        field_name: field_node.text.strip
      }
    end

    def parse_forms(parent_node)
      parent_node.xpath('./FORM').map do |form|
        parse_form(form)
      end
    end

    def parse_form(form_node)
      {
        type: 'form',
        name: form_node['name'],
        keyfield: form_node['keyfield'],
        table: form_node['table'],
        linkfield: form_node['linkfield'],
        width: form_node['tw'],
        height: form_node['th'],
        noorg: form_node['noorg'],
        fields: parse_form_fields(form_node)
      }
    end

    def parse_form_fields(form_node)
      fields = []
      
      form_node.xpath('./TEXTFIELD').each do |field|
        fields << parse_form_textfield(field)
      end
      
      form_node.xpath('./COMBOBOX').each do |field|
        fields << parse_combobox(field)
      end
      
      form_node.xpath('./COMBOLIST').each do |field|
        fields << parse_combolist(field)
      end
      
      form_node.xpath('./TEXTAREA').each do |field|
        fields << parse_textarea(field)
      end
      
      form_node.xpath('./CHECKBOX').each do |field|
        fields << parse_form_checkbox(field)
      end
      
      form_node.xpath('./TEXTDATE').each do |field|
        fields << parse_form_textdate(field)
      end
      
      fields
    end

    def parse_form_textfield(field_node)
      {
        type: 'textfield',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        required: field_node['required'],
        field_name: field_node.text.strip
      }
    end

    def parse_combobox(field_node)
      {
        type: 'combobox',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        lpfield: field_node['lpfield'],
        lptable: field_node['lptable'],
        lpkey: field_node['lpkey'],
        linkfield: field_node['linkfield'],
        noorg: field_node['noorg'],
        field_name: field_node.text.strip
      }
    end

    def parse_combolist(field_node)
      data_options = field_node.xpath('./DATA').map(&:text)
      {
        type: 'combolist',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        options: data_options,
        field_name: field_node.text.strip
      }
    end

    def parse_textarea(field_node)
      {
        type: 'textarea',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_form_checkbox(field_node)
      {
        type: 'checkbox',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_form_textdate(field_node)
      {
        type: 'textdate',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_actions(parent_node)
      actions_node = parent_node.at_xpath('./ACTIONS')
      return [] unless actions_node

      actions_node.xpath('./ACTION').map do |action|
        {
          function: action['fnct'],
          title: action['title'],
          phase: action['phase'],
          text: action.text.strip
        }
      end
    end

    def parse_subgrids(parent_node)
      parent_node.xpath('./GRID').map do |grid|
        parse_grid(grid)
      end
    end

    def parse_jasper(jasper_node)
      {
        type: 'jasper',
        name: jasper_node['name'],
        reportfile: jasper_node['reportfile'],
        filtered: jasper_node['filtered']
      }
    end

    def parse_filter(filter_node)
      {
        type: 'filter',
        name: filter_node['name'],
        location: filter_node['location'],
        drilldowns: parse_drilldowns(filter_node),
        reports: parse_filter_reports(filter_node)
      }
    end

    def parse_drilldowns(filter_node)
      filter_node.xpath('./DRILLDOWN').map do |drilldown|
        {
          keyfield: drilldown['keyfield'],
          name: drilldown['name'],
          listfield: drilldown['listfield'],
          table: drilldown['table'],
          wherefield: drilldown['wherefield'],
          pos: drilldown['pos'],
          noorg: drilldown['noorg']
        }
      end
    end

    def parse_filter_reports(filter_node)
      filter_node.xpath('./JASPER').map do |jasper|
        parse_jasper(jasper)
      end
    end
  end
end
