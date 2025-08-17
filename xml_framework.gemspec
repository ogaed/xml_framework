require_relative "lib/xml_framework/version"

Gem::Specification.new do |spec|
  spec.name        = "xml_framework"
  spec.version     = XmlFramework::VERSION
  spec.authors     = ["XML Framework Team"]
  spec.email       = ["team@xmlframework.com"]
  spec.homepage    = "https://github.com/xmlframework/xml_framework"
  spec.summary     = "Ruby framework for building web applications from XML templates"
  spec.description = "A Ruby framework that converts XML templates into full-featured Rails web applications with PostgreSQL integration"
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  spec.bindir = "bin"
  spec.executables = ["xml_framework"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 7.0.0"
  spec.add_dependency "nokogiri", ">= 1.13.0"
  spec.add_dependency "pg", ">= 1.1"
  
  spec.add_development_dependency "rspec", "~> 3.0"
end
