module XmlFramework
  class Generator
    def initialize(app_name, xml_path)
      @app_name = app_name
      @xml_path = xml_path
      @parsed_xml = Parser.new(xml_path).parse
    end
    
    def generate
      create_rails_app
      setup_database
      generate_controllers
      generate_views
      generate_routes
      puts "XML Framework app '#{@app_name}' generated successfully!"
    end
    
    private
    
    def create_rails_app
      system("rails new #{@app_name} -d postgresql --skip-javascript --skip-turbolinks")
      Dir.chdir(@app_name)
    end
    
    def setup_database
      # Create database configuration
      db_config = <<~YAML
        default: &default
          adapter: postgresql
          encoding: unicode
          pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
          username: <%= ENV.fetch("DATABASE_USER", "postgres") %>
          password: <%= ENV.fetch("DATABASE_PASSWORD", "") %>
          host: <%= ENV.fetch("DATABASE_HOST", "localhost") %>

        development:
          <<: *default
          database: #{@app_name}_development

        test:
          <<: *default
          database: #{@app_name}_test

        production:
          <<: *default
          database: #{@app_name}_production
          username: #{@app_name}
          password: <%= ENV["#{@app_name.upcase}_DATABASE_PASSWORD"] %>
      YAML
      
      File.write('config/database.yml', db_config)
    end
    
    def generate_controllers
      # Generate main application controller
      controller_content = <<~RUBY
        class ApplicationController < ActionController::Base
          protect_from_forgery with: :exception
          before_action :authenticate_user! if #{@parsed_xml[:app][:authentication]}
        end
      RUBY
      
      File.write('app/controllers/application_controller.rb', controller_content)
      
      # Generate XML app controller
      xml_controller = <<~RUBY
        class XmlAppController < ApplicationController
          def dashboard
            @dashboards = #{@parsed_xml[:dashboards].inspect}
            @dashboard_data = load_dashboard_data
          end
          
          def desk
            @desk_name = params[:desk]
            @desk = find_desk(@desk_name)
            @desk_data = load_desk_data(@desk)
          end
          
          private
          
          def find_desk(name)
            #{@parsed_xml[:desks].inspect}.find { |d| d[:name] == name }
          end
          
          def load_dashboard_data
            # Load data for dashboard tiles from database
            {}
          end
          
          def load_desk_data(desk)
            # Load data for desk components from database
            {}
          end
        end
      RUBY
      
      File.write('app/controllers/xml_app_controller.rb', xml_controller)
    end
    
    def generate_views
      # Create layout
      layout_content = <<~ERB
        <!DOCTYPE html>
        <html>
          <head>
            <title>#{@parsed_xml[:app][:title] || @app_name}</title>
            <meta name="viewport" content="width=device-width,initial-scale=1">
            <%= csrf_meta_tags %>
            <%= csp_meta_tag %>
            
            <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
          </head>

          <body>
            <nav class="navbar navbar-expand-lg navbar-dark bg-dark">
              <div class="container">
                <a class="navbar-brand" href="/">#{@parsed_xml[:app][:title] || @app_name}</a>
                <div class="navbar-nav">
                  #{generate_menu_html}
                </div>
              </div>
            </nav>
            
            <div class="container mt-4">
              <%= yield %>
            </div>
            
            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
          </body>
        </html>
      ERB
      
      File.write('app/views/layouts/application.html.erb', layout_content)
      
      # Create dashboard view
      dashboard_view = <<~ERB
        <% @dashboards.each do |dashboard| %>
          <%= raw XmlFramework.render_component(dashboard, @dashboard_data) %>
        <% end %>
      ERB
      
      Dir.mkdir('app/views/xml_app') unless Dir.exist?('app/views/xml_app')
      File.write('app/views/xml_app/dashboard.html.erb', dashboard_view)
      
      # Create desk view
      desk_view = <<~ERB
        <% if @desk %>
          <h1><%= @desk[:title] %></h1>
          <% @desk[:components].each do |component| %>
            <%= raw XmlFramework.render_component(component, @desk_data) %>
          <% end %>
        <% else %>
          <div class="alert alert-danger">Desk not found</div>
        <% end %>
      ERB
      
      File.write('app/views/xml_app/desk.html.erb', desk_view)
    end
    
    def generate_routes
      routes_content = <<~RUBY
        Rails.application.routes.draw do
          root 'xml_app#dashboard'
          get 'desk/:desk', to: 'xml_app#desk', as: 'desk'
          
          # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
        end
      RUBY
      
      File.write('config/routes.rb', routes_content)
    end
    
    def generate_menu_html
      menu_html = ""
      @parsed_xml[:menu].each do |menu|
        if menu[:items].any?
          menu_html += <<~HTML
            <div class="dropdown">
              <a class="nav-link dropdown-toggle" href="#" role="button" data-bs-toggle="dropdown">
                <i class="#{menu[:icon]}"></i> #{menu[:title]}
              </a>
              <ul class="dropdown-menu">
                #{menu[:items].map { |item| 
                  "<li><a class=\"dropdown-item\" href=\"/desk/#{item[:desk]}\"><i class=\"#{item[:icon]}\"></i> #{item[:title]}</a></li>" 
                }.join}
              </ul>
            </div>
          HTML
        else
          menu_html += "<a class=\"nav-link\" href=\"/desk/#{menu[:name]}\"><i class=\"#{menu[:icon]}\"></i> #{menu[:title]}</a>"
        end
      end
      menu_html
    end
  end
end
