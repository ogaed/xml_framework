require_relative '../lib/xml_framework'

module XmlFrameworkApp
  class Application < Rails::Application
    config.load_defaults 7.0
    
    # Add the XML framework to the load path
    config.autoload_paths += %W(#{config.root}/lib)
    
    # Initialize the XML framework
    config.after_initialize do
      if File.exist?(Rails.root.join('config', 'app.xml'))
        Rails.application.xml_app = XmlFramework::Application.new(
          Rails.root.join('config', 'app.xml')
        )
      end
    end
  end
end

# Add accessor for the XML app
class Rails::Application
  attr_accessor :xml_app
end
