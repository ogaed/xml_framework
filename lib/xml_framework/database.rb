require 'pg'

module XmlFramework
  class Database
    attr_reader :connection

    def initialize
      @connection = if ENV['DATABASE_URL'].present?
                      PG.connect(ENV['DATABASE_URL'])
                    else
                      PG.connect(
                        host: ENV['DB_HOST'] || 'localhost',
                        port: ENV['DB_PORT'] || 5432,
                        dbname: ENV['DB_NAME'] || 'xml_framework_db',
                        user: ENV['DB_USER'] || 'postgres',
                        password: ENV['DB_PASSWORD'] || 'password'
                      )
                    end
    end

    def self.from_env
      new
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
  end
end
