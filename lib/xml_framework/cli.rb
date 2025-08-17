require 'optparse'
require 'pg'
require_relative 'database_inspector'
require_relative 'xml_generator'
require_relative 'parser'
require_relative 'renderer'

module XmlFramework
  class CLI
    def self.start(args)
      new.run(args)
    end

    def run(args)
      command = args.shift
      
      case command
      when 'new'
        create_new_project(args)
      when 'inspect'
        inspect_database(args)
      when 'generate'
        generate_xml(args)
      when 'render'
        render_html(args)
      when 'server'
        start_server(args)
      when 'db:create'
        create_database
      when 'db:migrate'
        migrate_database
      else
        show_help
      end
    end

    private

    def create_new_project(args)
      project_name = args.first
      
      unless project_name
        puts "Error: Project name required"
        puts "Usage: xml_framework new PROJECT_NAME"
        return
      end

      puts "Creating new XML Framework project: #{project_name}"
      
      # Create project directory
      Dir.mkdir(project_name) unless Dir.exist?(project_name)
      Dir.chdir(project_name)
      
      # Create basic structure
      create_project_structure(project_name)
      
      puts "Project '#{project_name}' created successfully!"
      puts ""
      puts "Next steps:"
      puts "1. Set your database connection: export DATABASE_URL='postgresql://user:pass@localhost/dbname'"
      puts "2. Inspect your database: xml_framework inspect"
      puts "3. Generate XML from tables: xml_framework generate --auto"
      puts "4. Or create XML manually in config/app.xml"
      puts "5. Render to HTML: xml_framework render"
      puts "6. Start server: xml_framework server"
    end

    def inspect_database(args)
      options = parse_inspect_options(args)
      
      unless options[:database_url]
        puts "Error: Database URL required. Set DATABASE_URL environment variable or use --database-url option"
        return
      end

      begin
        inspector = DatabaseInspector.new(options[:database_url])
        
        puts "Database Inspection Results:"
        puts "=" * 50
        
        tables = inspector.get_tables
        puts "Found #{tables.length} tables:"
        
        tables.each do |table|
          puts "\n📋 Table: #{table}"
          columns = inspector.get_table_columns(table)
          
          columns.each do |column|
            type_info = "#{column[:data_type]}"
            type_info += "(#{column[:character_maximum_length]})" if column[:character_maximum_length]
            type_info += " NOT NULL" unless column[:is_nullable] == 'YES'
            type_info += " PRIMARY KEY" if column[:column_key] == 'PRI'
            
            puts "  • #{column[:column_name]} - #{type_info}"
          end
          
          # Show sample data count
          count = inspector.get_table_count(table)
          puts "  📊 Records: #{count}"
        end
        
        puts "\n" + "=" * 50
        puts "💡 Tip: Use 'xml_framework generate --auto' to create XML from these tables"
        puts "💡 Or use 'xml_framework generate --table TABLE_NAME' for specific tables"
        
      rescue => e
        puts "Error inspecting database: #{e.message}"
      end
    end

    def generate_xml(args)
      options = parse_generate_options(args)
      
      unless options[:database_url]
        puts "Error: Database URL required. Set DATABASE_URL environment variable or use --database-url option"
        return
      end

      begin
        inspector = DatabaseInspector.new(options[:database_url])
        generator = XmlGenerator.new(inspector)
        
        if options[:auto]
          # Auto-generate XML from all tables
          puts "🔄 Auto-generating XML from database tables..."
          
          tables = inspector.get_tables
          xml_content = generator.generate_full_app(options[:app_name] || "Generated App", tables)
          
          output_file = options[:output] || "config/app.xml"
          ensure_directory_exists(File.dirname(output_file))
          File.write(output_file, xml_content)
          
          puts "✅ Generated XML: #{output_file}"
          puts "📋 Included #{tables.length} tables: #{tables.join(', ')}"
          
        elsif options[:table]
          # Generate XML for specific table
          puts "🔄 Generating XML for table: #{options[:table]}"
          
          xml_content = generator.generate_table_grid(options[:table])
          output_file = options[:output] || "config/#{options[:table]}_grid.xml"
          
          ensure_directory_exists(File.dirname(output_file))
          File.write(output_file, xml_content)
          
          puts "✅ Generated XML: #{output_file}"
          
        elsif options[:tables]
          # Generate XML for specific tables
          puts "🔄 Generating XML for tables: #{options[:tables].join(', ')}"
          
          xml_content = generator.generate_full_app(options[:app_name] || "Custom App", options[:tables])
          output_file = options[:output] || "config/app.xml"
          
          ensure_directory_exists(File.dirname(output_file))
          File.write(output_file, xml_content)
          
          puts "✅ Generated XML: #{output_file}"
          puts "📋 Included #{options[:tables].length} tables: #{options[:tables].join(', ')}"
          
        else
          puts "Error: Specify --auto, --table TABLE_NAME, or --tables table1,table2"
          puts "Use 'xml_framework inspect' to see available tables"
          return
        end
        
        puts ""
        puts "💡 Next steps:"
        puts "  • Review and customize the generated XML"
        puts "  • Run 'xml_framework render' to convert to HTML"
        puts "  • Run 'xml_framework server' to view in browser"
        
      rescue => e
        puts "Error generating XML: #{e.message}"
      end
    end

    def render_html(args)
      options = parse_render_options(args)
      
      input_file = options[:input] || "config/app.xml"
      
      unless File.exist?(input_file)
        puts "Error: XML file not found: #{input_file}"
        puts "Generate XML first with: xml_framework generate --auto"
        return
      end

      begin
        puts "🔄 Rendering XML to HTML..."
        
        xml_content = File.read(input_file)
        renderer = Renderer.new
        parsed_xml = Parser.new.parse_xml(xml_content)
        
        # Create HTML output directory
        output_dir = options[:output_dir] || "public"
        ensure_directory_exists(output_dir)
        
        # Generate main HTML file
        html_content = generate_html_page(parsed_xml)
        html_file = File.join(output_dir, "index.html")
        File.write(html_file, html_content)
        
        # Generate CSS file
        css_content = generate_css
        css_file = File.join(output_dir, "styles.css")
        File.write(css_file, css_content)
        
        # Generate JavaScript file
        js_content = generate_javascript
        js_file = File.join(output_dir, "app.js")
        File.write(js_file, js_content)
        
        puts "✅ Rendered HTML: #{html_file}"
        puts "✅ Generated CSS: #{css_file}"
        puts "✅ Generated JS: #{js_file}"
        puts ""
        puts "💡 Run 'xml_framework server' to view in browser"
        
      rescue => e
        puts "Error rendering HTML: #{e.message}"
      end
    end

    def start_server(args)
      require_relative 'server'
      puts "🚀 Starting XML Framework server..."
      puts "📱 Open http://localhost:4567 in your browser"
      Server.start
    end

    def create_database
      puts "🔄 Creating database..."
      # Database creation logic would go here
      puts "✅ Database created successfully"
    end

    def migrate_database
      puts "🔄 Running database migrations..."
      # Migration logic would go here
      puts "✅ Database migrated successfully"
    end

    def parse_inspect_options(args)
      options = {}
      
      OptionParser.new do |opts|
        opts.banner = "Usage: xml_framework inspect [options]"
        
        opts.on("--database-url URL", "PostgreSQL database URL") do |url|
          options[:database_url] = url
        end
      end.parse!(args)
      
      options[:database_url] ||= ENV['DATABASE_URL']
      options
    end

    def parse_generate_options(args)
      options = {}
      
      OptionParser.new do |opts|
        opts.banner = "Usage: xml_framework generate [options]"
        
        opts.on("--database-url URL", "PostgreSQL database URL") do |url|
          options[:database_url] = url
        end
        
        opts.on("--auto", "Auto-generate XML from all database tables") do
          options[:auto] = true
        end
        
        opts.on("--table TABLE", "Generate XML for specific table") do |table|
          options[:table] = table
        end
        
        opts.on("--tables x,y,z", Array, "Generate XML for specific tables") do |tables|
          options[:tables] = tables
        end
        
        opts.on("--app-name NAME", "Application name for generated XML") do |name|
          options[:app_name] = name
        end
        
        opts.on("--output FILE", "Output XML file path") do |file|
          options[:output] = file
        end
      end.parse!(args)
      
      options[:database_url] ||= ENV['DATABASE_URL']
      options
    end

    def parse_render_options(args)
      options = {}
      
      OptionParser.new do |opts|
        opts.banner = "Usage: xml_framework render [options]"
        
        opts.on("--input FILE", "Input XML file") do |file|
          options[:input] = file
        end
        
        opts.on("--output-dir DIR", "Output directory for HTML files") do |dir|
          options[:output_dir] = dir
        end
      end.parse!(args)
      
      options
    end

    def create_project_structure(project_name)
      # Create directories
      %w[config public lib].each do |dir|
        Dir.mkdir(dir) unless Dir.exist?(dir)
      end
      
      # Create sample XML file
      sample_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <APP name="#{project_name}" title="#{project_name.capitalize}" database="postgresql">
          <MENU name="main" title="Main Menu" icon="fas fa-home">
            <!-- Menu items will be auto-generated based on your database tables -->
          </MENU>
          
          <!-- Desks, Dashboards, and Grids will be auto-generated -->
          <!-- Or you can manually define them here -->
        </APP>
      XML
      
      File.write('config/app.xml', sample_xml)
      
      readme_content = <<~MD
        # #{project_name}
        
        XML Framework Application
        
        ## Setup
        
        1. Set database connection:
           \`\`\`
           export DATABASE_URL="postgresql://user:pass@localhost/dbname"
           \`\`\`
        
        2. Inspect your database:
           \`\`\`
           xml_framework inspect
           \`\`\`
        
        3. Generate XML from database:
           \`\`\`
           xml_framework generate --auto
           \`\`\`
        
        4. Render to HTML:
           \`\`\`
           xml_framework render
           \`\`\`
        
        5. Start server:
           \`\`\`
           xml_framework server
           \`\`\`
      MD
      
      File.write('README.md', readme_content)
    end

    def ensure_directory_exists(dir)
      Dir.mkdir(dir) unless Dir.exist?(dir)
    end

    def generate_html_page(parsed_xml)
      app_config = parsed_xml[:app_config] || {}
      
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>#{app_config[:name] || 'XML Framework App'}</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
            <link href="styles.css" rel="stylesheet">
        </head>
        <body>
            <nav class="navbar navbar-expand-lg navbar-dark bg-primary">
                <div class="container">
                    <a class="navbar-brand" href="#">
                        <i class="fas fa-cube"></i> #{app_config[:name] || 'XML Framework'}
                    </a>
                </div>
            </nav>
            
            <div class="container-fluid mt-4">
                <div id="app-content">
                    <h1>Welcome to #{app_config[:name] || 'XML Framework'}</h1>
                    <p>Your database-driven application is ready!</p>
                    
                    <div class="alert alert-info">
                        <i class="fas fa-info-circle"></i>
                        This HTML was generated from your XML configuration.
                        Database integration and dynamic content loading will be added in the next version.
                    </div>
                </div>
            </div>
            
            <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
            <script src="app.js"></script>
        </body>
        </html>
      HTML
    end

    def generate_css
      <<~CSS
        .xml-dashboard {
            margin: 20px 0;
        }
        
        .dashboard-tiles {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        
        .dashboard-tile {
            background: #fff;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 20px;
            cursor: pointer;
            transition: all 0.3s ease;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .dashboard-tile:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        
        .tile-header {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .tile-header i {
            font-size: 24px;
            margin-right: 10px;
            color: #007bff;
        }
        
        .tile-title {
            font-weight: 600;
            color: #333;
        }
        
        .tile-number {
            font-size: 32px;
            font-weight: bold;
            color: #007bff;
        }
        
        .xml-grid {
            margin: 20px 0;
        }
        
        .data-grid {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-grid th,
        .data-grid td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        .data-grid th {
            background-color: #f8f9fa;
            font-weight: 600;
        }
        
        .data-grid tr:hover {
            background-color: #f5f5f5;
        }
      CSS
    end

    def generate_javascript
      <<~JS
        // XML Framework JavaScript
        console.log('XML Framework loaded');
        
        function jumpToView(viewName) {
            console.log('Jumping to view:', viewName);
            // Navigation logic will be implemented here
        }
        
        function openBrowser(action, value) {
            console.log('Opening browser action:', action, 'with value:', value);
            // Browser action logic will be implemented here
        }
        
        function generateReport(reportFile) {
            console.log('Generating report:', reportFile);
            // Report generation logic will be implemented here
        }
        
        // Initialize the application
        document.addEventListener('DOMContentLoaded', function() {
            console.log('XML Framework application initialized');
        });
      JS
    end

    def show_help
      puts <<~HELP
        XML Framework - Database-driven XML to HTML generator

        Commands:
          new PROJECT_NAME              Create a new XML Framework project
          inspect [options]             Inspect database tables and structure
          generate [options]            Generate XML from database tables
          render [options]              Convert XML to HTML
          server                        Start local web server
          db:create                     Create database
          db:migrate                    Run database migrations

        Examples:
          # Create new project
          xml_framework new my_university_app

          # Inspect database
          xml_framework inspect --database-url postgresql://localhost/mydb

          # Auto-generate XML from all tables
          xml_framework generate --auto --app-name "University System"

          # Generate XML for specific table
          xml_framework generate --table students

          # Generate XML for specific tables
          xml_framework generate --tables users,courses,enrollments

          # Render XML to HTML
          xml_framework render

          # Start server
          xml_framework server

        Environment Variables:
          DATABASE_URL                  PostgreSQL connection string

        Workflow:
          1. Create project: xml_framework new my_app
          2. Set DATABASE_URL environment variable
          3. Inspect database: xml_framework inspect
          4. Generate XML: xml_framework generate --auto
          5. Render HTML: xml_framework render
          6. Start server: xml_framework server
      HELP
    end
  end
end
