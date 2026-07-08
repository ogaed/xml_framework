module XmlFramework
  class JsonQuery
    def initialize(query, component, view_key:, field_renderer:)
      @query = query
      @component = component
      @view_key = view_key
      @field_renderer = field_renderer
    end

    def column_defs
      (@component[:fields] || []).map do |field|
        editable = field[:type].to_s == 'editfield'
        {
          field: field[:field_name],
          headerName: field[:title] || field[:field_name],
          width: field[:width].to_i.nonzero? || 120,
          filter: !editable,
          sortable: true,
          editable: editable,
          cellRenderer: editable ? nil : 'htmlCellRenderer'
        }.compact
      end
    end

    def header_json
      {
        url: "/jsondata?view=#{@view_key}",
        columnDefs: column_defs
      }
    end

    def rows(page: 1, per_page: 30, sort_col: nil, sort_dir: 'asc', extra_where: nil)
      keyfield = @component[:keyfield]
      data = @query.fetch_rows(
        page: page,
        per_page: per_page,
        sort_col: sort_col,
        sort_dir: sort_dir,
        extra_where: extra_where
      )

      data.each_with_index.map do |row, index|
        formatted = {}
        (@component[:fields] || []).each do |field|
          name = field[:field_name]
          value = row[name]
          if field[:type].to_s == 'editfield'
            formatted[name] = @field_renderer.raw_grid_value(field, value)
          else
            formatted[name] = @field_renderer.render_grid_cell(
              field,
              value,
              row: row,
              key_value: row[keyfield]
            )
          end
        end

        formatted['KF'] = row[keyfield]
        formatted['CL'] = "/xml_app/#{@view_key.split(':').first}?data=#{row[keyfield]}"
        formatted['row_number_counter'] = ((page - 1) * per_page) + index + 1
        formatted
      end
    end

    def paginated_response(page:, per_page:, sort_col:, sort_dir:, extra_where: nil)
      rows_data = rows(
        page: page,
        per_page: per_page,
        sort_col: sort_col,
        sort_dir: sort_dir,
        extra_where: extra_where
      )
      total = @query.count_rows(extra_where: extra_where)

      {
        page: page.to_i,
        total: (total.to_f / per_page).ceil,
        records: total,
        rows: rows_data,
        columnDefs: column_defs
      }
    end
  end
end
