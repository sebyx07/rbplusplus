# frozen_string_literal: true

require 'rubygems'
require 'rbplusplus'

RbPlusPlus::Extension.new 'my_math' do |e|
  e.sources File.expand_path(File.dirname(__FILE__) + '/code/MyMath.h')
  e.namespace 'my_math'
end
