class JsonDataController < ApplicationController
  def show
    view_key = params[:view] || xml_session.view_key
    return render json: { rows: [], records: 0, page: 1, total: 0 } unless xml_engine

    data = xml_engine.grid_json(
      view_key,
      page: params[:page] || 1,
      per_page: params[:rows] || 30,
      sort_col: params[:sidx],
      sort_dir: params[:sord]
    )

    render json: data
  end
end
