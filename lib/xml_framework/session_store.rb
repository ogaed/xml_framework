module XmlFramework
  # Mirrors Baraza HttpSession attribute naming (BWeb.java).
  class SessionStore
    attr_reader :session, :user_id, :username

    def initialize(rails_session, user_id: nil, username: nil)
      @session = rails_session
      @user_id = user_id || rails_session[:user_id]
      @username = username || rails_session[:username]
    end

    def view_key
      session[:viewkey]
    end

    def view_key=(key)
      session[:viewkey] = key
    end

    def xml_config
      session[:xmlcnf]
    end

    def xml_config=(name)
      session[:xmlcnf] = name
    end

    def data_for(view_key)
      session[data_key(view_key)]
    end

    def set_data(view_key, value)
      session[data_key(view_key)] = value
    end

    def sort_for(view_key)
      session["S#{view_key}"] || {}
    end

    def set_sort(view_key, column:, direction:)
      session["S#{view_key}"] = { column: column, direction: direction }
    end

    def filter_for(view_key)
      session["F#{view_key}"]
    end

    def set_filter(view_key, where_clause)
      session["F#{view_key}"] = where_clause
    end

    def filter_param(name)
      session[name.to_s]
    end

    def set_filter_param(name, value)
      session[name.to_s] = value
    end

    def signed_in?
      user_id.present?
    end

    def sign_in!(user_id:, username:, roles: [], access_levels: [], super_user: false)
      session[:user_id] = user_id
      session[:username] = username
      session[:roles] = roles
      session[:access_levels] = access_levels
      session[:super_user] = super_user
      @user_id = user_id
      @username = username
    end

    def sign_out!
      session.delete(:user_id)
      session.delete(:username)
      session.delete(:roles)
      session.delete(:access_levels)
      session.delete(:super_user)
      session.delete(:viewkey)
      @user_id = nil
      @username = nil
    end

    private

    def data_key(view_key)
      "d#{view_key}"
    end
  end
end
