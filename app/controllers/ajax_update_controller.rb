class AjaxUpdateController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    view_key = params[:view] || xml_session.view_key
    return render json: { success: false, msg: 'Framework not loaded' } unless xml_engine

    result = xml_engine.inline_update(
      view_key: view_key,
      record_id: params[:id] || params[:data],
      field: params[:field] || params[:sidx],
      value: params[:value] || params[params[:field]]
    )

    render json: result
  end
end
