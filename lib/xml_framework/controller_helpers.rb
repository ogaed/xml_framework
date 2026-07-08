module XmlFramework
  module ControllerHelpers
    extend ActiveSupport::Concern

    included do
      before_action :set_xml_app
      helper_method :xml_session, :xml_engine, :current_username
    end

    private

    def set_xml_app
      @xml_app = Rails.application.xml_app
    end

    def xml_session
      @xml_session ||= XmlFramework::SessionStore.new(
        session,
        user_id: session[:user_id],
        username: session[:username]
      )
    end

    def xml_engine
      return nil unless @xml_app

      @xml_engine ||= @xml_app.web_engine(xml_session)
    end

    def current_username
      xml_session.username
    end

    def authenticate_user!
      return if xml_session.signed_in?

      redirect_to login_path, alert: 'Please sign in to continue.'
    end

    def user_signed_in?
      xml_session.signed_in?
    end
  end
end
