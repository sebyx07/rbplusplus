# frozen_string_literal: true
require_relative 'lib/rbplusplus/version'

Gem::Specification.new do |s|
  s.name = 'rbplusplus'
  s.version = RbPlusPlus::VERSION
  s.license = 'MIT'
  s.summary = 'Ruby library to generate Rice wrapper code'
  s.homepage = 'https://github.com/jasonroelofs/rbplusplus'
  s.author = 'Jason Roelofs'
  s.email = 'jasongroelofs@gmail.com'
  s.required_ruby_version = '>= 3.0.0'

  s.description = <<-END
Rb++ combines the powerful query interface of rbgccxml and the Rice library to
make Ruby wrapping extensions of C++ libraries easier to write than ever.
  END

  s.add_dependency 'rbgccxml', '~> 1.1'
  s.add_dependency 'rice', '~> 2.1'

  patterns = %w[TODO Rakefile lib/**/*.rb]

  s.files = patterns.map { |p| Dir.glob(p) }.flatten

  s.test_files = [Dir.glob('test/**/*.rb'), Dir.glob('test/headers/**/*')].flatten

  s.require_paths = ['lib']
end
