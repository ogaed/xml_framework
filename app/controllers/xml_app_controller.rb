class XmlAppController < ApplicationController
  def index
    redirect_to dashboard_path
  end

  def dashboard
    @page_content = xml_engine&.render_page('1') || default_dashboard
    @menu_html = xml_engine&.menu_html
    render 'show'
  end

  def show
    desk_key = params[:key]
    view_key = params[:view] || desk_key
    data_item = params[:data]

    @page_content = xml_engine&.render_page(view_key, data_item: data_item)
    @menu_html = xml_engine&.menu_html

    if @page_content
      render 'show'
    else
      redirect_to dashboard_path, alert: 'Page not found'
    end
  end

  private

  def default_dashboard
    <<~HTML
      <div class="alert alert-info">
        <h4>XML Framework Ready</h4>
        <p>Place your XML configuration file at <code>config/app.xml</code> to get started.</p>
      </div>
    HTML
  end
end
