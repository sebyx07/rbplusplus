$:.unshift File.expand_path(File.dirname(__FILE__))
$:.unshift File.expand_path(File.dirname(__FILE__) + "/rbplusplus")

require 'rubygems'
require 'rbgccxml'

require 'inflector'
require 'fileutils'
require 'singleton'
require 'rbplusplus/rbplusplus'

require 'fileutils'

module RbPlusPlus

  RBPP_COMMENT = "// This file generated by rb++"

  autoload :Extension, "rbplusplus/extension"
  autoload :RbModule, "rbplusplus/module"
  autoload :Logger, "rbplusplus/logger"

  module Builders
    autoload :Base, "rbplusplus/builders/base"
    autoload :ClassBuilder, "rbplusplus/builders/class"
    autoload :DirectorBuilder, "rbplusplus/builders/director"
    autoload :ExtensionBuilder, "rbplusplus/builders/extension"
    autoload :ModuleBuilder, "rbplusplus/builders/module"
    autoload :EnumerationBuilder, "rbplusplus/builders/enumeration"
    autoload :TypesManager, "rbplusplus/builders/types_manager"
  end

  module Writers
    autoload :Base, "rbplusplus/writers/base"
    autoload :ExtensionWriter, "rbplusplus/writers/extension"
    autoload :MultipleFilesWriter, "rbplusplus/writers/multiple_files_writer"
    autoload :SingleFileWriter, "rbplusplus/writers/single_file_writer"
  end
end

class String #:nodoc:
  # Functionize attempts to rename a string in a cpp function friendly way.
  #
  # vector<float>::x => vector_float__x
  def functionize
    gsub("::","_").gsub(/[ ,<>]/, "_").gsub("*", "Ptr")
  end
end

require 'rbplusplus/transformers/rbgccxml'
require 'rbplusplus/transformers/node_cache'
require 'rbplusplus/transformers/node'
require 'rbplusplus/transformers/node_reference'
require 'rbplusplus/transformers/function'
require 'rbplusplus/transformers/class'
require 'rbplusplus/transformers/module'

