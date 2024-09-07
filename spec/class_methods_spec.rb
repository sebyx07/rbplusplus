# frozen_string_literal: true
describe 'Correct handling of static methods' do
  specify 'should handle complex static methods' do
    RbPlusPlus::Extension.new 'complex_test' do |e|
      e.sources full_dir('headers/complex_static_methods.h')
      e.namespace 'complex'
    end

    require 'complex_test'

    Multiply.multiply(SmallInteger.new(2), SmallInteger.new(2)).should == 4
  end
end
