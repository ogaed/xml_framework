class FiltersController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    view_key = params[:view] || xml_session.view_key
    return render json: { success: false, msg: 'Framework not loaded' } unless xml_engine

    result = xml_engine.apply_filter(
      view_key: view_key,
      filter_name: params[:filter] || params[:filtername],
      value: params[:value]
    )

    render json: result
  end
end
