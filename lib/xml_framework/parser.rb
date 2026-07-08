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

      # Parse ACCORDION components
      desk_node.xpath('./ACCORDION').each do |accordion|
        components << parse_accordion(accordion)
      end

      # Parse FORM components at desk level
      desk_node.xpath('./FORM').each do |form|
        components << parse_form(form)
      end
      
      components
    end

    def parse_dashboard(dashboard_node)
      {
        type: 'dashboard',
        name: dashboard_node['name'],
        width: dashboard_node['w'],
        refresh: dashboard_node['refresh'],
        tiles: parse_tiles(dashboard_node),
        links: parse_dashboard_links(dashboard_node)
      }
    end

    def parse_dashboard_links(dashboard_node)
      links_node = dashboard_node.at_xpath('./LINKS')
      return [] unless links_node

      links_node.xpath('./LINK').map do |link|
        {
          title: link['title'] || link.text.strip,
          view: link['view'],
          url: link['url'],
          icon: link['icon']
        }
      end
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
        role: grid_node['role'],
        access: grid_node['access'],
        keyfield: grid_node['keyfield'],
        table: grid_node['table'],
        where: grid_node['where'],
        orderby: grid_node['orderby'],
        limit: grid_node['limit'],
        noorg: grid_node['noorg'],
        linkfield: grid_node['linkfield'],
        filter: grid_node['filter'],
        filterfield: grid_node['filterfield'],
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

      grid_node.xpath('./WEBLINK').each { |f| fields << parse_weblink(f) }
      grid_node.xpath('./TEXTLINK').each { |f| fields << parse_textlink(f) }
      grid_node.xpath('./PICTURE').each { |f| fields << parse_picture(f) }
      grid_node.xpath('./EDITFIELD').each { |f| fields << parse_editfield(f) }
      grid_node.xpath('./BUTTON').each { |f| fields << parse_button(f) }
      grid_node.xpath('./ACTION').each { |f| fields << parse_grid_action(f) }
      grid_node.xpath('./SEARCH').each { |f| fields << parse_search(f) }
      grid_node.xpath('./ROWCOUNTER').each { |f| fields << parse_rowcounter(f) }
      
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

    def parse_weblink(field_node)
      {
        type: 'weblink',
        width: field_node['w'],
        title: field_node['title'],
        url: field_node['url'],
        field_name: field_node.text.strip
      }
    end

    def parse_textlink(field_node)
      {
        type: 'textlink',
        width: field_node['w'],
        title: field_node['title'],
        url: field_node['url'],
        field_name: field_node.text.strip
      }
    end

    def parse_picture(field_node)
      {
        type: 'picture',
        width: field_node['w'],
        title: field_node['title'],
        pictures: field_node['pictures'],
        access: field_node['access'],
        field_name: field_node.text.strip
      }
    end

    def parse_editfield(field_node)
      {
        type: 'editfield',
        width: field_node['w'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_button(field_node)
      {
        type: 'button',
        width: field_node['w'],
        title: field_node['title'],
        js_function: field_node['js.function'] || field_node['js_function'],
        field_name: field_node.text.strip
      }
    end

    def parse_grid_action(field_node)
      {
        type: 'action',
        width: field_node['w'],
        title: field_node['title'] || field_node['action'],
        field_name: field_node.text.strip
      }
    end

    def parse_search(field_node)
      {
        type: 'search',
        width: field_node['w'],
        title: field_node['title'],
        js: field_node['js'],
        field_name: field_node.text.strip
      }
    end

    def parse_rowcounter(field_node)
      {
        type: 'rowcounter',
        width: field_node['w'],
        title: field_node['title'] || '#',
        field_name: field_node.text.strip.presence || 'row_number_counter'
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
        role: form_node['role'],
        access: form_node['access'],
        keyfield: form_node['keyfield'],
        table: form_node['table'],
        linkfield: form_node['linkfield'],
        width: form_node['tw'],
        height: form_node['th'],
        noorg: form_node['noorg'],
        collapse: form_node['collapse'],
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

      form_node.xpath('./TEXTDECIMAL').each do |field|
        fields << parse_form_textdecimal(field)
      end

      form_node.xpath('./PASSWORD').each do |field|
        fields << parse_password(field)
      end

      form_node.xpath('./EDITOR').each do |field|
        fields << parse_editor(field)
      end

      form_node.xpath('./MULTISELECT').each do |field|
        fields << parse_multiselect(field)
      end

      form_node.xpath('./HTML').each do |field|
        fields << parse_html(field)
      end

      form_node.xpath('./PICTURE').each do |field|
        fields << parse_form_picture(field)
      end

      form_node.xpath('./FILE').each do |field|
        fields << parse_form_file(field)
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

    def parse_form_textdecimal(field_node)
      {
        type: 'textdecimal',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_password(field_node)
      {
        type: 'password',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_editor(field_node)
      {
        type: 'editor',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
      }
    end

    def parse_multiselect(field_node)
      {
        type: 'multiselect',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        lptable: field_node['lptable'],
        lpfield: field_node['lpfield'],
        lpkey: field_node['lpkey'],
        field_name: field_node.text.strip
      }
    end

    def parse_html(field_node)
      {
        type: 'html',
        html: field_node['html'],
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
          role: action['role'],
          access: action['access'],
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
        role: jasper_node['role'],
        access: jasper_node['access'],
        reportfile: jasper_node['reportfile'],
        filtered: jasper_node['filtered'],
        linkfield: jasper_node['linkfield'],
        linkparams: jasper_node['linkparams']
      }
    end

    def parse_accordion(node)
      panels = []
      node.xpath('./FORM').each { |f| panels << parse_form(f) }
      node.xpath('./GRID').each { |g| panels << parse_grid(g) }

      {
        type: 'accordion',
        name: node['name'],
        role: node['role'],
        access: node['access'],
        panels: panels
      }
    end

    def parse_filter(filter_node)
      tabs = []
      filter_node.xpath('./FILTERGRID').each { |g| tabs << parse_filter_grid(g) }
      filter_node.xpath('./DRILLDOWN').each { |d| tabs << parse_drilldown_node(d) }
      filter_node.xpath('./FILTERFORM').each { |f| tabs << parse_filter_form(f) }
      filter_node.xpath('./JASPER').each { |j| tabs << parse_jasper(j) }

      {
        type: 'filter',
        name: filter_node['name'],
        role: filter_node['role'],
        access: filter_node['access'],
        location: filter_node['location'],
        tabs: tabs,
        drilldowns: parse_drilldowns(filter_node),
        reports: parse_filter_reports(filter_node)
      }
    end

    def parse_filter_grid(node)
      grid = parse_grid(node)
      grid[:type] = 'filtergrid'
      grid[:name] = node['name'] || grid[:name]
      grid[:filter] = node['filter']
      grid[:filterfield] = node['filterfield']
      grid
    end

    def parse_filter_form(node)
      form = parse_form(node)
      form[:type] = 'filterform'
      form[:name] = node['name'] || form[:name]
      form
    end

    def parse_drilldown_node(node)
      {
        type: 'drilldown',
        name: node['name'],
        filter: node['filter'],
        filterfield: node['filterfield'],
        keyfield: node['keyfield'],
        listfield: node['listfield'],
        table: node['table'],
        where: node['where'],
        wherefield: node['wherefield'],
        orderby: node['orderby'],
        pos: node['pos'],
        noorg: node['noorg'],
        children: node.xpath('./DRILLDOWN').map { |c| parse_drilldown_node(c) }
      }
    end

    def parse_form_picture(field_node)
      {
        type: 'picture',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        pictures: field_node['pictures'],
        access: field_node['access'],
        field_name: field_node.text.strip
      }
    end

    def parse_form_file(field_node)
      {
        type: 'file',
        width: field_node['w'],
        height: field_node['h'],
        x: field_node['x'],
        y: field_node['y'],
        title: field_node['title'],
        field_name: field_node.text.strip
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
