# frozen_string_literal: true

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
$:.unshift File.expand_path(File.dirname(__FILE__) + '/generated')

require 'pry'
require 'rbplusplus'
require 'fileutils'

module FileDirectoryHelpers
  def full_dir(path)
    File.expand_path(File.join(File.dirname(__FILE__), path))
  end
end

module TestHelpers
  def silence_logging
    RbPlusPlus::Logger.silent!
  end

  def test_setup
    silence_logging
  end
end

RSpec.configure do |config|
  config.include(FileDirectoryHelpers)
  config.include(TestHelpers)

  config.expect_with(:rspec) do |c|
    c.syntax = :should
  end

  config.before(:all) do
    test_setup
  end

  config.order = 'random'

  config.before do
    FileUtils.rm_rf('spec/generated')
  end
end
