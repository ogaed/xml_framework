require 'fileutils'

module XmlFramework
  class Engine < ::Rails::Engine
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer 'xml_framework.dirs' do |app|
      %w[public/uploads public/reports reports].each do |dir|
        path = app.root.join(dir)
        FileUtils.mkdir_p(path) unless path.exist?
      end
    end
  end
end
