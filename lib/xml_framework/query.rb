module XmlFramework
  class Query
    attr_reader :component, :connection

    def initialize(database, component, org_id: nil, link_data: nil)
      @database = database
      @connection = database.connection
      @component = component
      @org_id = org_id
      @link_data = link_data
    end

    def fetch_rows(page: 1, per_page: 30, sort_col: nil, sort_dir: 'asc', extra_where: nil)
      sql = build_select_sql(extra_where: extra_where, sort_col: sort_col, sort_dir: sort_dir)
      offset = [(page.to_i - 1), 0].max * per_page.to_i

      paginated = "#{sql} LIMIT #{per_page.to_i} OFFSET #{offset}"
      result = connection.exec(paginated)
      result.to_a
    end

    def count_rows(extra_where: nil)
      sql = "SELECT COUNT(*) FROM #{component[:table]} #{build_where_clause(extra_where)}"
      connection.exec(sql).first['count'].to_i
    end

    def fetch_record(key_value)
      keyfield = component[:keyfield]
      sql = "SELECT * FROM #{component[:table]} WHERE #{keyfield} = $1 LIMIT 1"
      result = connection.exec_params(sql, [key_value])
      result.first
    end

    def insert(params, fields, remote_ip: nil, username: nil, user_id: nil)
      values = build_field_values(params, fields, remote_ip: remote_ip, username: username, user_id: user_id)
      columns = values.keys
      placeholders = columns.each_index.map { |i| "$#{i + 1}" }.join(', ')

      sql = "INSERT INTO #{component[:table]} (#{columns.join(', ')}) VALUES (#{placeholders}) RETURNING #{component[:keyfield]}"
      result = connection.exec_params(sql, columns.map { |c| values[c] })
      result.first&.fetch(component[:keyfield], nil)
    end

    def update(key_value, params, fields, remote_ip: nil, username: nil, user_id: nil)
      values = build_field_values(params, fields, remote_ip: remote_ip, username: username, user_id: user_id)
      return key_value if values.empty?

      set_clause = values.keys.each_index.map { |i| "#{values.keys[i]} = $#{i + 2}" }.join(', ')
      sql = "UPDATE #{component[:table]} SET #{set_clause} WHERE #{component[:keyfield]} = $1 RETURNING #{component[:keyfield]}"
      result = connection.exec_params(sql, [key_value] + values.values)
      result.first&.fetch(component[:keyfield], key_value)
    end

    def delete(key_value)
      sql = "DELETE FROM #{component[:table]} WHERE #{component[:keyfield]} = $1"
      connection.exec_params(sql, [key_value])
      true
    end

    def inline_update(key_value, field_name, value)
      sql = "UPDATE #{component[:table]} SET #{field_name} = $1 WHERE #{component[:keyfield]} = $2 RETURNING #{component[:keyfield]}"
      connection.exec_params(sql, [value, key_value])
      true
    end

    def execute_tile(tile)
      field = tile[:fields]&.first
      fnct = field&.dig(:function) || 'COUNT(*)'
      sql = "SELECT #{fnct} AS value FROM #{tile[:table]} #{build_tile_where(tile)}"
      sql += " GROUP BY #{tile[:groupby]}" if tile[:groupby].present?

      result = connection.exec(sql)
      result.first&.fetch('value', 0)
    rescue StandardError
      0
    end

    def combobox_options(field)
      lptable = field[:lptable]
      lpfield = field[:lpfield]
      lpkey = field[:lpkey] || field[:field_name]
      return [] unless lptable && lpfield

      where_parts = []
      where_parts << field[:where] if field[:where].present?
      if field[:linkfield].present? && @link_data.present?
        where_parts << "#{field[:linkfield]} = '#{sanitize_literal(@link_data)}'"
      end
      if @org_id.present? && field[:noorg].blank?
        where_parts << "org_id = #{@org_id.to_i}"
      end

      sql = if lpkey == lpfield
              "SELECT #{lpfield} FROM #{lptable}"
            else
              "SELECT #{lpkey}, #{lpfield} FROM #{lptable}"
            end
      sql += " WHERE #{where_parts.join(' AND ')}" if where_parts.any?
      sql += " ORDER BY #{lpfield}"

      connection.exec(sql).to_a
    rescue StandardError
      []
    end

    private

    def build_select_sql(extra_where: nil, sort_col: nil, sort_dir: nil)
      fields = component[:fields]&.map { |f| f[:field_name] }&.reject(&:blank?)
      select_list = fields&.any? ? fields.join(', ') : '*'
      order = if sort_col.present?
                "ORDER BY #{sort_col} #{sort_dir.to_s.upcase == 'DESC' ? 'DESC' : 'ASC'}"
              elsif component[:orderby].present?
                "ORDER BY #{component[:orderby]}"
              else
                ''
              end

      limit = component[:limit].present? ? "LIMIT #{component[:limit].to_i}" : ''

      "SELECT #{select_list} FROM #{component[:table]} #{build_where_clause(extra_where)} #{order} #{limit}".squeeze(' ').strip
    end

    def build_where_clause(extra_where)
      parts = []
      parts << "(#{component[:where]})" if component[:where].present?
      parts << "(#{extra_where})" if extra_where.present?
      if component[:linkfield].present? && @link_data.present?
        parts << "(#{component[:linkfield]} = '#{sanitize_literal(@link_data)}')"
      end
      if @org_id.present? && component[:noorg].blank?
        parts << "(org_id = #{@org_id.to_i})"
      end

      parts.any? ? "WHERE #{parts.join(' AND ')}" : ''
    end

    def build_tile_where(tile)
      parts = []
      parts << "(#{tile[:where]})" if tile[:where].present?
      if @org_id.present?
        parts << "(org_id = #{@org_id.to_i})"
      end
      parts.any? ? "WHERE #{parts.join(' AND ')}" : ''
    end

    def build_field_values(params, fields, remote_ip:, username:, user_id:)
      values = {}

      fields.each do |field|
        next if field[:enabled] == false || field[:canedit] == false

        name = field[:field_name]
        type = field[:type].to_s

        case type
        when 'default'
          values[name] = field[:default_value]
        when 'userfield'
          values[name] = user_id
        when 'username'
          values[name] = username
        when 'remoteip'
          values[name] = remote_ip
        when 'checkbox'
          raw = params[name]
          values[name] = %w[true 1 on yes].include?(raw.to_s.downcase)
        when 'textdate'
          values[name] = params[name].presence
        when 'textdecimal', 'textnumber'
          values[name] = params[name].to_s.delete(',').presence
        when 'multiselect'
          values[name] = Array(params[name]).join(',')
        when 'function'
          next
        when 'levelkey'
          next
        when 'picture', 'file'
          values[name] = params[name] if params[name].is_a?(String)
        else
          values[name] = params[name] if params.key?(name)
        end
      end

      values.compact
    end

    def sanitize_literal(value)
      value.to_s.gsub("'", "''")
    end
  end
end
