require 'pg'

module XmlFramework
  class Database
    def initialize
      @connection = PG.connect(
        host: ENV['DB_HOST'] || 'localhost',
        port: ENV['DB_PORT'] || 5432,
        dbname: ENV['DB_NAME'] || 'xml_framework_db',
        user: ENV['DB_USER'] || 'postgres',
        password: ENV['DB_PASSWORD'] || 'password'
      )
    end

    def execute_tile_query(tile)
      query = build_tile_query(tile)
      result = @connection.exec(query)
      result.first&.values&.first || 0
    end

    def execute_grid_query(grid)
      query = build_grid_query(grid)
      result = @connection.exec(query)
      result.to_a
    end

    def get_dashboard_data
      # Return sample dashboard data
      {
        total_applicants: 1250,
        admitted_students: 890,
        unpaid_applications: 45,
        completed_applications: 1205
      }
    end

    def get_desk_data(desk_key)
      # Return sample data based on desk key
      case desk_key
      when '965'
        get_applications_data
      when '920'
        get_admissions_data
      else
        { components: [] }
      end
    end

    private

    def build_tile_query(tile)
      select_clause = tile[:fields].first[:function] || "COUNT(*)"
      from_clause = tile[:table]
      where_clause = tile[:where] || "1=1"
      group_clause = tile[:groupby] ? "GROUP BY #{tile[:groupby]}" : ""

      "SELECT #{select_clause} FROM #{from_clause} WHERE #{where_clause} #{group_clause}"
    end

    def build_grid_query(grid)
      field_names = grid[:fields].map { |f| f[:field_name] }.join(', ')
      from_clause = grid[:table]
      where_clause = grid[:where] ? "WHERE #{grid[:where]}" : ""
      order_clause = grid[:orderby] ? "ORDER BY #{grid[:orderby]}" : ""
      limit_clause = grid[:limit] ? "LIMIT #{grid[:limit]}" : ""

      "SELECT #{field_names} FROM #{from_clause} #{where_clause} #{order_clause} #{limit_clause}"
    end

    def get_applications_data
      {
        components: [
          {
            type: 'grid',
            data: [
              { applying_id: 1, surname: 'Smith', first_name: 'John', email: 'john@example.com' },
              { applying_id: 2, surname: 'Johnson', first_name: 'Jane', email: 'jane@example.com' }
            ]
          }
        ]
      }
    end

    def get_admissions_data
      {
        components: [
          {
            type: 'grid',
            data: [
              { registration_id: 1, first_name: 'John', surname: 'Smith', existing_id: 'STU001' },
              { registration_id: 2, first_name: 'Jane', surname: 'Johnson', existing_id: 'STU002' }
            ]
          }
        ]
      }
    end
  end
end
