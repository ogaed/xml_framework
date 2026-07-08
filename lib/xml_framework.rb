require_relative 'xml_framework/version'
require_relative 'xml_framework/engine'
require_relative 'xml_framework/session_store'
require_relative 'xml_framework/element_navigator'
require_relative 'xml_framework/query'
require_relative 'xml_framework/field_renderer'
require_relative 'xml_framework/json_query'
require_relative 'xml_framework/access_control'
require_relative 'xml_framework/file_uploader'
require_relative 'xml_framework/views/accordion_renderer'
require_relative 'xml_framework/views/filter_renderer'
require_relative 'xml_framework/views/jasper_renderer'
require_relative 'xml_framework/web_engine'
require_relative 'xml_framework/controller_helpers'
require_relative 'xml_framework/parser'
require_relative 'xml_framework/renderer'
require_relative 'xml_framework/database'
require_relative 'xml_framework/components'

module XmlFramework
  class Application
    attr_reader :config, :parser, :renderer, :database, :navigator

    def initialize(xml_file_path, database: nil)
      @parser = Parser.new
      @renderer = Renderer.new
      @database = database || Database.from_env
      @config = @parser.parse_file(xml_file_path)
      @navigator = ElementNavigator.new(@config)
    end

    def web_engine(session_store)
      WebEngine.new(@config, database: @database, session_store: session_store)
    end

    def render_page(desk_key, session_store: nil, data_item: nil)
      if session_store
        web_engine(session_store).render_page(desk_key, data_item: data_item)
      else
        desk = find_desk_by_key(desk_key)
        return nil unless desk
        @renderer.render_desk(desk, @database)
      end
    end

    def generate_rails_app
      create_controllers
      create_views
      create_models
      create_routes
    end

    private

    def find_desk_by_key(key)
      @config[:desks].find { |desk| desk[:key] == key.to_s }
    end

    def create_controllers
      # Generate Rails controllers based on XML structure
      File.write('app/controllers/xml_app_controller.rb', generate_main_controller)
    end

    def create_views
      # Generate ERB views from XML components
      @config[:desks].each do |desk|
        view_content = @renderer.render_desk_view(desk)
        File.write("app/views/xml_app/#{desk[:name].downcase.gsub(' ', '_')}.html.erb", view_content)
      end
    end

    def create_models
      # Generate ActiveRecord models from XML table references
      tables = extract_tables_from_config
      tables.each do |table|
        model_content = generate_model(table)
        File.write("app/models/#{table.singularize}.rb", model_content)
      end
    end

    def create_routes
      routes_content = generate_routes
      File.write('config/routes_xml.rb', routes_content)
    end

    def generate_main_controller
      <<~RUBY
        class XmlAppController < ApplicationController
          before_action :authenticate_user!
          
          def dashboard
            @dashboard_data = XmlFramework::Database.new.get_dashboard_data
            render 'dashboard'
          end

          #{@config[:desks].map { |desk| generate_action_method(desk) }.join("\n\n")}

          private

          def authenticate_user!
            # Add your authentication logic here
            redirect_to login_path unless user_signed_in?
          end

          def user_signed_in?
            # Implement your user authentication check
            session[:user_id].present?
          end
        end
      RUBY
    end

    def generate_action_method(desk)
      action_name = desk[:name].downcase.gsub(' ', '_')
      <<~RUBY
        def #{action_name}
          @desk_data = XmlFramework::Database.new.get_desk_data('#{desk[:key]}')
          render '#{action_name}'
        end
      RUBY
    end

    def extract_tables_from_config
      tables = Set.new
      @config[:desks].each do |desk|
        desk[:components].each do |component|
          tables.add(component[:table]) if component[:table]
        end
      end
      tables.to_a
    end

    def generate_model(table)
      class_name = table.singularize.camelize
      <<~RUBY
        class #{class_name} < ApplicationRecord
          self.table_name = '#{table}'
          
          # Add validations and associations based on XML structure
          # This would be enhanced based on the XML field definitions
        end
      RUBY
    end

    def generate_routes
      routes = @config[:desks].map do |desk|
        action_name = desk[:name].downcase.gsub(' ', '_')
        "  get '/#{action_name}', to: 'xml_app##{action_name}'"
      end

      <<~RUBY
        Rails.application.routes.draw do
          root 'xml_app#dashboard'
        #{routes.join("\n")}
        end
      RUBY
    end
  end
end
