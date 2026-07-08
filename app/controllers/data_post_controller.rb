class DataPostController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false

  def create
    view_key = params[:view] || xml_session.view_key
    return render json: { success: false, msg: 'Framework not loaded' } unless xml_engine

    if params[:oper].to_s == 'action' && params[:fnct].present?
      result = xml_engine.execute_action(
        view_key: view_key,
        function: params[:fnct],
        data_item: params[:data]
      )
      return render json: result
    end

    uploaded = extract_uploaded_files
    result = xml_engine.save_form(
      view_key: view_key,
      params: request.request_parameters,
      data_item: params[:data],
      remote_ip: request.remote_ip,
      uploaded_files: uploaded
    )

    render json: result
  end

  def destroy
    view_key = params[:view] || xml_session.view_key
    return render json: { success: false, msg: 'Framework not loaded' } unless xml_engine

    result = xml_engine.save_form(
      view_key: view_key,
      params: request.request_parameters.merge(oper: 'delete'),
      data_item: params[:data],
      remote_ip: request.remote_ip
    )

    render json: result
  end

  private

  def extract_uploaded_files
    return {} unless request.content_mime_type&.multipart?

    files = {}
    params.each do |key, value|
      files[key] = value if value.respond_to?(:read) && value.respond_to?(:original_filename)
    end
    files
  end
end
