# frozen_string_literal: true

describe 'Wrapping Classes within classes' do
  before(:all) do
    RbPlusPlus::Extension.new 'nested' do |e|
      e.sources full_dir('headers/nested_classes.h')
      e.namespace 'classes'
    end

    require 'nested'
  end

  specify 'should properly make nested classes available' do
    TestClass.new.should_not be_nil
    TestClass::InnerClass.new.should_not be_nil
    TestClass::InnerClass::Inner2.new.should_not be_nil
  end
end
