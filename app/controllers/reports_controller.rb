class ReportsController < ApplicationController
  def create
    return render json: { success: false, msg: 'Framework not loaded' } unless xml_engine

    result = xml_engine.generate_report(
      report_file: params[:report] || params[:reportfile],
      params: report_params
    )

    render json: result
  end

  private

  def report_params
    params.permit(:date_from, :date_to, :view, :report, :reportfile).to_h
  end
end
