$: << File.expand_path("lib")

require "qoi/version"

Gem::Specification.new do |s|
  s.name        = "qoi"
  s.version     = QOI::VERSION
  s.summary     = "Quite OK Image Format Implementation"
  s.description = "Quite OK Image Format Implementation in pure Ruby"
  s.authors     = ["Aaron Patterson"]
  s.email       = "tenderlove@ruby-lang.org"
  s.files       = `git ls-files -z`.split("\x0")
  s.test_files  = s.files.grep(%r{^test/})
  s.homepage    = "https://github.com/tenderlove/qoi"
  s.license     = "Apache-2.0"

  s.add_development_dependency 'chunky_png', '>= 1.4.0'
  s.add_development_dependency 'minitest', '>= 5.15'
  s.add_development_dependency 'rake', '>= 13.0'
  s.add_development_dependency 'net-http', '>= 0.9.1'
  s.add_development_dependency 'uri', '>= 0.11.1'
  s.add_development_dependency 'rubyzip', '>= 3.2.2'

  s.required_ruby_version '>= 3.3.0'
end
