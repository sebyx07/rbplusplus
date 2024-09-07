# frozen_string_literal: true

module RbPlusPlus
  module Utils
    def self.string_as_variable(string)
      string.gsub('::', '_').gsub(/[ ,<>]/, '_').gsub('*', 'Ptr')
    end
  end
end
