require 'pg'

module XmlFramework
  class DatabaseInspector
    def initialize(database_url)
      @connection = PG.connect(database_url)
    end

    def get_tables
      query = <<~SQL
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_type = 'BASE TABLE'
        ORDER BY table_name
      SQL
      
      result = @connection.exec(query)
      result.map { |row| row['table_name'] }
    end

    def get_table_columns(table_name)
      query = <<~SQL
        SELECT 
          column_name,
          data_type,
          character_maximum_length,
          is_nullable,
          column_default,
          CASE 
            WHEN column_name IN (
              SELECT column_name 
              FROM information_schema.key_column_usage 
              WHERE table_name = $1 
              AND constraint_name IN (
                SELECT constraint_name 
                FROM information_schema.table_constraints 
                WHERE table_name = $1 AND constraint_type = 'PRIMARY KEY'
              )
            ) THEN 'PRI'
            ELSE ''
          END as column_key
        FROM information_schema.columns 
        WHERE table_name = $1 
        ORDER BY ordinal_position
      SQL
      
      result = @connection.exec_params(query, [table_name])
      result.map do |row|
        {
          column_name: row['column_name'],
          data_type: row['data_type'],
          character_maximum_length: row['character_maximum_length'],
          is_nullable: row['is_nullable'],
          column_default: row['column_default'],
          column_key: row['column_key']
        }
      end
    end

    def get_table_count(table_name)
      query = "SELECT COUNT(*) as count FROM #{table_name}"
      result = @connection.exec(query)
      result.first['count'].to_i
    rescue
      0
    end

    def get_sample_data(table_name, limit = 5)
      query = "SELECT * FROM #{table_name} LIMIT #{limit}"
      result = @connection.exec(query)
      result.to_a
    rescue
      []
    end

    def close
      @connection.close if @connection
    end
  end
end
