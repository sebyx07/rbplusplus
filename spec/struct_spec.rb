# frozen_string_literal: true

describe 'Nested Struct' do
  specify 'should be accessible' do
    RbPlusPlus::Extension.new 'nested' do |e|
      e.sources full_dir('headers/nested_struct.h')
      e.namespace 'nested'
    end

    require 'nested'

    Klass::NestedStruct.new.one.should == 1

    lambda do
      Klass::PrivateNestedStruct.new
    end.should raise_error(NameError)
  end
end
