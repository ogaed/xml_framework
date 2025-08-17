class XmlAppController < ApplicationController
  def index
    redirect_to dashboard_path
  end
  
  def dashboard
    @dashboard_data = @xml_app&.render_page('1') || default_dashboard
    render 'dashboard'
  end
  
  def show
    desk_key = params[:key]
    @page_content = @xml_app&.render_page(desk_key)
    
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
