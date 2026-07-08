# frozen_string_literal: true

class Rails::Application
  attr_accessor :xml_app unless method_defined?(:xml_app)
end

Rails.application.config.after_initialize do
  xml_path = Rails.root.join('config', 'app.xml')
  next unless xml_path.exist?

  Rails.application.xml_app = XmlFramework::Application.new(xml_path)
end
