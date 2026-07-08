require 'rails/generators'

module XmlFramework
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Install XML Framework into a Rails application'

      def copy_initializer
        template 'xml_framework.rb', 'config/initializers/xml_framework.rb'
      end

      def copy_sample_xml
        return if File.exist?('config/app.xml')

        source = File.expand_path('../../../../config/app.xml', __dir__)
        copy_file source, 'config/app.xml'
      end

      def show_instructions
        say "\nXML Framework installed.", :green
        say "\nNext steps:"
        say "  1. Add to config/routes.rb:  mount XmlFramework::Engine => '/'"
        say "  2. Set DATABASE_URL or configure config/database.yml for PostgreSQL"
        say "  3. Edit config/app.xml to define your UI"
        say "  4. Run: rails db:create db:migrate (if needed) && rails server"
        say "  5. Login with admin / admin (demo) or your entitys table users\n"
      end
    end
  end
end
