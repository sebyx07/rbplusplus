# frozen_string_literal: true

require 'rdoc/task'

Rake::RDocTask.new do |rd|
  rd.main = 'README'
  rd.rdoc_files.include('README', 'lib/**/*.rb')
  rd.rdoc_files.exclude('**/jamis.rb')
  rd.template = File.expand_path(File.dirname(__FILE__) + '/lib/jamis.rb')
  rd.options << '--line-numbers' << '--inline-source'
end
