class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  before_action :set_xml_app
  
  private
  
  def set_xml_app
    @xml_app = Rails.application.xml_app
  end
  
  def authenticate_user!
    # Implement your authentication logic
    redirect_to login_path unless user_signed_in?
  end
  
  def user_signed_in?
    # Check if user is authenticated
    session[:user_id].present?
  end
end
