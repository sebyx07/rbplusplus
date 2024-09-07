# frozen_string_literal: true
describe 'Ruby Extension creation' do
  specify 'should create a valid Ruby extension' do
    RbPlusPlus::Extension.new 'ext_test' do |e|
      e.sources full_dir('headers/empty.h')
      e.writer_mode :single
    end

    require 'ext_test'
  end

  specify 'should create a valid Ruby extension without a block' do
    e = RbPlusPlus::Extension.new 'extension'
    e.sources full_dir('headers/empty.h')
    e.working_dir = File.join(File.expand_path(File.dirname(__FILE__)), 'generated')
    e.writer_mode :single
    e.build
    e.write
    e.compile

    require 'ext_test'
  end

  specify 'should properly build working dir as deep as needed' do
    path = File.join(File.expand_path(File.dirname(__FILE__)), 'generated', 'path1', 'path2')
    RbPlusPlus::Extension.new 'extension' do |e|
      e.sources full_dir('headers/empty.h')
      e.working_dir = path
      e.writer_mode :single
    end

    File.exist?(File.join(path, 'extconf.rb')).should eq(true)
  end
end
