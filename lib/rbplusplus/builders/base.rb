module RbPlusPlus
  module Builders

    # Top class for all source generation classes. A builder has three seperate
    # code "parts" to fill up for the source writer:
    #
    #   includes
    #   declarations
    #   body
    #
    # includes:
    #   The list of #include's needed for this builder's code to compile
    #
    # declarations:
    #   Any extra required functions or class declarations that will be defined
    #   outside of the main body of the code
    #
    # body:
    #   The body is the code that will go in the main control function
    #   of the file. For extensions, it's Init_extension_name() { [body] }.
    #   For classes it's usually a register_ClassName() { [body] }, and so on.
    #
    # All builders can access their parent and add pieces of code to any of these
    # three parts
    #
    class Base

      attr_reader :name, :node

      # Any given builder has a list of sub-builders of any type
      attr_accessor :builders

      # Builders need to constcuct the following code parts
      #
      # The list of includes this builder needs
      attr_accessor :includes
      # The list of declarations to add
      attr_accessor :declarations
      # Any prototypes
      attr_accessor :prototypes
      # The body code
      attr_accessor :body

      # Link to the parent builder who created said builder
      attr_accessor :parent

      # The name of the C++ variable related to this builder.
      attr_accessor :rice_variable
      attr_accessor :rice_variable_type

      # If the name of the element is something other than what GCCXML gives us
      # (say, using a typedef), then set the name here and it will be used
      # appropriately.
      attr_accessor :class_type

      # Create a new builder.
      def initialize(name, parser)
        @name = name
        @node = parser
        @builders = []
        @includes = []
        @declarations = []
        @prototypes = []
        @body = []
        @registered_nodes = []
      end

      # adds a register function to the Init or register of this node
      def register_node(node, register_func)
        @registered_nodes << [node, register_func]
      end

    private

      def nested_level(node, level=0)
        return level if node.is_a?(RbGCCXML::Namespace) || node.is_a?(RbGCCXML::Enumeration)
        return level if node.super_classes.length == 0
        node.super_classes.each do |sup|
          level = nested_level(sup, level+1)
        end
        return level
      end

    public

      # Sorts the registered nodes by hierachy, registering the base classes
      # first.
      #
      # this is necessary for Rice to know about inheritance
      def registered_nodes
        #sort by hierachy
        nodes = @registered_nodes.sort_by do |build, func|
          if build.node.nil?
            0
          else
            nested_level(build.node)
          end
        end

        #collect the sorted members
        nodes.collect do |node, func|
          func
        end
      end

      # The name of the header file to include
      # This is the file default, so long as it matches one of the export files
      # If not this returns all exported files.
      #
      # This was added to workaround badly declared namespaces
      def header_files(node)
        file = node.file_name(false)
        return [file] if self.class.sources.include?(file)
        self.class.sources
      end

      # Adds the necessary includes in order to compile the specified node
      def add_includes_for(node)
        header_files(node).each do |header|
          includes << "#include \"#{header}\""
        end
      end

      # Include any user specified include files
      def add_additional_includes
        self.class.additional_includes.each do |inc|
          includes << "#include \"#{inc}\""
        end
      end

      # Set a list of user specified include files
      def self.additional_includes=(addl)
        @@additional_includes = addl
      end

      # Get an array of user specified include files
      def self.additional_includes
        @@additional_includes || []
      end

      # A list of all the source files.  This is used in order to prevent files
      # that are not in the list from being included and mucking things up
      def self.sources=(sources)
        @@sources = sources
      end

      # Retrieves a list of user specified source files
      def self.sources
        @@sources || []
      end

      # All builders must implement this method
      def build
        raise "Builder needs to implement #build"
      end

      # Builders should use to_s to make finishing touches on the generated
      # code before it gets written out to a file.
      def to_s
        extras = []
        #Weird trailing } needs to be destroyed!!!
        if self.body.flatten[-1].strip == "}"
          extras << self.body.delete_at(-1)
        end

        return [
          self.includes.flatten.uniq,
          "",
          self.declarations,
          "",
          self.body,
          "",
          self.registered_nodes,
          extras
        ].flatten.join("\n")
      end

      # Get the full qualified name of the related gccxml node
      def qualified_name
        @node.qualified_name
      end

      # Register all classes
      def build_classes(classes = nil)
        classes ||= [@node.classes, @node.structs].flatten
        classes.each do |klass|
          next if klass.ignored? || klass.moved?
          next unless klass.public?
          builder = ClassBuilder.new(self, klass)
          builder.build
          builders << builder
        end
      end

      # Find and wrap up all enumerations
      def build_enumerations
        @node.enumerations.each do |enum|
          builder = EnumerationBuilder.new(self, enum)
          builder.build
          builders << builder
        end
      end

      # Builds up a string containing arguments.
      #  <tt>include_self</tt>: Boolean on whether to include the type information in the list.
      #  <tt>with_self</tt>:    Boolean on whether the list should include the explicit self.
      #
      def function_arguments_list(function, include_type = false, with_self = false)
        list = []
        function.arguments.map{|arg| [arg.cpp_type.to_s(true), arg.name]}.each_with_index do |parts, i|
          type = parts[0]
          name = parts[1] || "arg#{i}"
          tmp = "#{include_type ? type : ''} #{name}"
          list << tmp
        end

        if with_self
          list.unshift "#{include_type ? 'Rice::Object' : ''} self"
        end

        list
      end

      # Takes the results of function_arguments_list above and outputs it as
      # a comma delimited string. Doing this allows post-processing of the
      # list of argument as needed (such as in ExtensionBuilder#build_callback_wrapper).
      def function_arguments_string(*args)
        function_arguments_list(*args).join(",")
      end

      # Compatibility with Rice 1.0.1's explicit self requirement, build a quick
      # wrapper that includes a self and discards it, forwarding the call as needed.
      #
      # Returns: the name of the wrapper function
      def build_function_wrapper(function, append = "")
        return if function.ignored? || function.moved?
        wrapper_func = "wrap_#{function.qualified_name.functionize}#{append}"

        return_type = function.return_type.to_s(true)
        returns = "" if return_type == "void"
        returns ||= "return"

        declarations << "#{return_type} #{wrapper_func}(#{function_arguments_string(function, true, true)}) {"
        declarations << "\t#{returns} #{function.qualified_name}(#{function_arguments_string(function)});"
        declarations << "}"

        wrapper_func
      end

      # Compatibility with Rice 1.0.1's method overloading issues. Build a quick
      # wrapper that includes a self, forwarding the call as needed.
      #
      # Returns: the name of the function to send to Rice
      def build_method_wrapper(klass, method, append = "")
        return if method.ignored? || method.moved?

        if method.arguments.size == 1 && (fp = method.arguments[0].cpp_type.base_type).is_a?(RbGCCXML::FunctionType)
           Logger.info "Building callback wrapper for #{method.qualified_name}"
           build_method_callback_wrapper(method, fp, append)
        else
          wrapper_func = "wrap_#{method.qualified_name.functionize}#{append}"

          return_type = method.return_type.to_s(true)
          returns = "" if return_type == "void"
          returns ||= "return"

          args = function_arguments_list(method, true)

          parent = method.parent
          to_call = ""

          # Handles #as_instance_method designation
          if ((method.is_a?(RbGCCXML::Function) && method.as_instance_method?) || (method.is_a?(RbGCCXML::Method) && append != "")) &&
              (parent.is_a?(RbGCCXML::Class) || parent.is_a?(RbGCCXML::Struct))
            args.unshift "#{method.parent.qualified_name} *self"
            to_call = "self->#{method.renamed? ? method.cpp_name : method.name}"
          elsif append != ""
            args.unshift "Rice::Object self"
            to_call = method.qualified_name
          else
            return method.qualified_name
          end

          declarations << "#{return_type} #{wrapper_func}(#{args.join(",")}) {"
          declarations << "\t#{returns} #{to_call}(#{function_arguments_string(method)});"
          declarations << "}"

          wrapper_func
        end
      end

      # Build up C++ code to properly wrap up methods to take ruby block arguments
      # which forward off calls to callback functions.
      #
      # This works as such. We need two functions here, one to be the wrapper into Ruby
      # and one to be the wrapper around the callback function.
      #
      # The method wrapped into Ruby takes straight Ruby objects
      #
      # Current assumption: The callback argument is the only argument of the method
      def build_function_callback_wrapper(function, func_pointer, append = "")
        func_name = function.qualified_name.functionize
        yielding_method_name = "do_yeild_on_#{func_name}"
        wrapper_func = "wrap_for_callback_#{func_name}#{append}"

        fp_arguments = func_pointer.arguments
        fp_return = func_pointer.return_type

        returns = fp_return.to_s

        # The callback wrapper method.
        block_var_name = "_block_for_#{func_name}"
        declarations << "VALUE #{block_var_name};"
        declarations << "#{returns} #{yielding_method_name}(#{function_arguments_string(func_pointer, true)}) {"

        num_args = fp_arguments.length
        args_string = "#{num_args}"
        if num_args > 0
          args_string += ", #{function_arguments_list(func_pointer).map{|c| "to_ruby(#{c}).value()"}.join(",") }"
        end

        funcall = "rb_funcall(#{block_var_name}, rb_intern(\"call\"), #{args_string})"
        if returns == "void"
          declarations << "\t#{funcall};"
        else
          declarations << "\treturn from_ruby<#{returns}>(#{funcall});"
        end
        declarations << "}"

        # The method to get wrapped into Ruby
        declarations << "void #{wrapper_func}(Rice::Object self) {"
        declarations << "\t#{block_var_name} = rb_block_proc();"
        declarations << "\t#{function.qualified_name}(&#{yielding_method_name});"
        declarations << "}"

        wrapper_func
      end

      def build_method_callback_wrapper(method, func_pointer, append = "")
        func_name = method.qualified_name.functionize
        yielding_method_name = "do_yeild_on_#{func_name}"
        wrapper_func = "wrap_for_callback_#{func_name}#{append}"

        fp_arguments = func_pointer.arguments
        fp_return = func_pointer.return_type

        returns = fp_return.to_s

        # The callback wrapper method.
        block_var_name = "_block_for_#{func_name}"
        declarations << "VALUE #{block_var_name};"
        declarations << "#{returns} #{yielding_method_name}(#{function_arguments_string(func_pointer, true)}) {"

        num_args = fp_arguments.length
        args_string = "#{num_args}"
        if num_args > 0
          args_string += ", #{function_arguments_list(func_pointer).map{|c| "to_ruby(#{c}).value()"}.join(",") }"
        end

        funcall = "rb_funcall(#{block_var_name}, rb_intern(\"call\"), #{args_string})"
        if returns == "void"
          declarations << "\t#{funcall};"
        else
          declarations << "\treturn from_ruby<#{returns} >(#{funcall});"
        end
        declarations << "}"

        # The method to get wrapped into Ruby
        declarations << "VALUE #{wrapper_func}(#{method.parent.qualified_name} *self) {"
        declarations << "\t#{block_var_name} = rb_block_proc();"
        declarations << "\tself->#{method.name}(&#{yielding_method_name});"
        declarations << "\treturn Qnil;"
        declarations << "}"

        wrapper_func
      end


    end
  end
end
