module XmlFramework
  class XmlGenerator
    def initialize(database_inspector)
      @inspector = database_inspector
    end

    def generate_full_app(app_name, tables)
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <APP name="#{app_name}" title="#{app_name}" database="postgresql" authentication="true">
          #{generate_menu(tables)}
          
          #{generate_dashboard(tables)}
          
          #{generate_desks(tables)}
        </APP>
      XML
    end

    def generate_table_grid(table_name)
      columns = @inspector.get_table_columns(table_name)
      
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <DESK name="#{table_name.capitalize}" key="#{table_name}_desk">
          <GRID name="#{table_name.capitalize}" keyfield="id" table="#{table_name}">
            #{generate_grid_fields(columns)}
            
            <FORM name="#{table_name.capitalize}" keyfield="id" table="#{table_name}">
              #{generate_form_fields(columns)}
            </FORM>
          </GRID>
        </DESK>
      XML
    end

    private

    def generate_menu(tables)
      menu_items = tables.map do |table|
        <<~XML
          <MENU name="#{table}" title="#{table.capitalize}" icon="fas fa-table" desk="#{table}_desk" />
        XML
      end.join

      <<~XML
        <MENU name="main" title="Main Menu" icon="fas fa-home">
          <MENU name="dashboard" title="Dashboard" icon="fas fa-tachometer-alt" desk="dashboard_desk" />
          #{menu_items}
        </MENU>
      XML
    end

    def generate_dashboard(tables)
      tiles = tables.map do |table|
        <<~XML
          <TILE name="#{table}_count" title="Total #{table.capitalize}" table="#{table}" jumpview="#{table}_desk">
            <TEXTFIELD icon="fas fa-database" fnct="COUNT(*)">total_#{table}</TEXTFIELD>
          </TILE>
        XML
      end.join

      <<~XML
        <DESK name="Dashboard" key="dashboard_desk">
          <DASHBOARD name="Dashboard" w="1200" refresh="30">
            #{tiles}
          </DASHBOARD>
        </DESK>
      XML
    end

    def generate_desks(tables)
      tables.map do |table|
        generate_table_desk(table)
      end.join("\n")
    end

    def generate_table_desk(table_name)
      columns = @inspector.get_table_columns(table_name)
      
      <<~XML
        <DESK name="#{table_name.capitalize}" key="#{table_name}_desk">
          <GRID name="#{table_name.capitalize}" keyfield="id" table="#{table_name}" orderby="id">
            #{generate_grid_fields(columns)}
            
            <FORM name="#{table_name.capitalize}" keyfield="id" table="#{table_name}">
              #{generate_form_fields(columns)}
            </FORM>
            
            <ACTIONS>
              <ACTION fnct="INSERT" title="Add New" phase="before">add_#{table_name}</ACTION>
              <ACTION fnct="UPDATE" title="Update" phase="before">update_#{table_name}</ACTION>
              <ACTION fnct="DELETE" title="Delete" phase="before">delete_#{table_name}</ACTION>
            </ACTIONS>
          </GRID>
        </DESK>
      XML
    end

    def generate_grid_fields(columns)
      columns.map do |column|
        width = calculate_field_width(column)
        field_type = map_database_type_to_xml(column[:data_type])
        
        case field_type
        when 'checkbox'
          "<CHECKBOX w=\"#{width}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</CHECKBOX>"
        when 'textdate'
          "<TEXTDATE w=\"#{width}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</TEXTDATE>"
        when 'textdecimal'
          "<TEXTDECIMAL w=\"#{width}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</TEXTDECIMAL>"
        else
          "<TEXTFIELD w=\"#{width}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</TEXTFIELD>"
        end
      end.join("\n            ")
    end

    def generate_form_fields(columns)
      y_position = 10
      
      columns.map do |column|
        width = 200
        height = 25
        field_type = map_database_type_to_xml(column[:data_type])
        required = column[:is_nullable] == 'NO' ? 'true' : 'false'
        
        field_xml = case field_type
        when 'checkbox'
          "<CHECKBOX w=\"#{width}\" h=\"#{height}\" x=\"10\" y=\"#{y_position}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</CHECKBOX>"
        when 'textdate'
          "<TEXTDATE w=\"#{width}\" h=\"#{height}\" x=\"10\" y=\"#{y_position}\" title=\"#{column[:column_name].capitalize}\" required=\"#{required}\">#{column[:column_name]}</TEXTDATE>"
        when 'textarea'
          "<TEXTAREA w=\"#{width}\" h=\"60\" x=\"10\" y=\"#{y_position}\" title=\"#{column[:column_name].capitalize}\">#{column[:column_name]}</TEXTAREA>"
        else
          "<TEXTFIELD w=\"#{width}\" h=\"#{height}\" x=\"10\" y=\"#{y_position}\" title=\"#{column[:column_name].capitalize}\" required=\"#{required}\">#{column[:column_name]}</TEXTFIELD>"
        end
        
        y_position += field_type == 'textarea' ? 80 : 40
        field_xml
      end.join("\n              ")
    end

    def calculate_field_width(column)
      case column[:data_type]
      when 'boolean'
        50
      when 'date', 'timestamp', 'timestamptz'
        120
      when 'integer', 'bigint'
        80
      when 'numeric', 'decimal'
        100
      else
        if column[:character_maximum_length]
          [column[:character_maximum_length].to_i * 8, 200].min
        else
          150
        end
      end
    end

    def map_database_type_to_xml(db_type)
      case db_type.downcase
      when 'boolean'
        'checkbox'
      when 'date', 'timestamp', 'timestamptz'
        'textdate'
      when 'numeric', 'decimal', 'real', 'double precision'
        'textdecimal'
      when 'text'
        'textarea'
      else
        'textfield'
      end
    end
  end
end
