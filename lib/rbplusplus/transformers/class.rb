module RbGCCXML
  class Class < Node
    # Class can include nested classes and nested structs.
    #
    # Class can also include external methods/functions as class level methods
    # also supports instance level methods
    #
    # ex. 
    #
    #   math_class.includes node.namespaces("Math").functions("mod")
    #
    # or for a instance method:
    #
    #   math_class.includes node.namespaces("Math").functions("mod").as_instance_method
    #
    # or for nesting a class/struct:
    #
    #   math_class.includes node.namespaces("Math").classes("Degree")
    #
    def includes(val)
      if (val.is_a?(RbGCCXML::Struct) || val.is_a?(RbGCCXML::Class))
        cache[:classes] ||= []
        cache[:classes] << RbPlusPlus::NodeReference.new(val)
      else
        cache[:methods] ||= []
        cache[:methods] << RbPlusPlus::NodeReference.new(val)
      end
      val.moved = true 
    end
    
    alias_method :node_classes, :classes
    def classes(*args) #:nodoc:
      find_with_cache(:classes, node_classes(*args))
    end

    alias_method :node_methods, :methods
    def methods(*args) #:nodoc:
      find_with_cache(:methods, node_methods(*args))
    end

    # Specify which superclass to use.
    # Because Rice doesn't support multiple inheritance right now,
    # we need to know which superclass Rice should use for this class.
    # An error message will show on classes with mutiple superclasses
    # where this method hasn't been used yet.
    #
    # klass should be the node for the class you want to wrap
    def use_superclass(node)
      cache[:use_superclass] = node
    end

    def _get_superclass
      cache[:use_superclass]
    end

    # Like #use_superclass, this method allows the user to specify 
    # which constructor Rice should expose to Ruby. 
    # Rice currently, because of the lack of method overloading, 
    # only supports one constructor definition. Having multiple
    # in the code will work, but only the last defined will actually
    # work. 
    def use_constructor(node)
      cache[:use_constructor] = node
    end

    def _get_constructor
      cache[:use_constructor]
    end

    # Sometimes, type manipulation, moving nodes around, or flat
    # ignoring nodes just doesn't do the trick and you need to write
    # your own custom wrapper code. This method is for that. There are
    # two parts to custom code: the declaration and the wrapping. 
    #
    # The Declaration:
    #   This is the actual custom code you write. It may need to take
    #   a pointer to the class type as the first parameter (or if this
    #   is a singleton method, give it Rice::Object self)
    #   and follow with that any parameters you want. 
    #
    # The Wrapping
    #   The wrapping is the custom (usually one-line) bit of Rice code that
    #   hooks up your declaration with the class in question. To ensure that
    #   you doesn't need to know the variable of the ruby class object, 
    #   use <class> and rb++ will replace it as needed.
    #
    # Example (taken from Ogre.rb's wrapping of Ogre)
    #
    #   decl = <<-END
    #   int RenderTarget_getCustomAttributeInt(Ogre::RenderTarget* self, const std::string& name) {
    #     int value(0);
    #     self->getCustomAttribute(name, &value);
    #     return value;
    #   }
    #   END
    #   wrapping = "<class>.define_method(\"get_custom_attribute_int\", &RenderTarget_getCustomAttributeInt);"
    #
    #   rt.add_custom_code(decl, wrapping)
    #
    # This method works as an aggregator, so feel free to use it any number
    # of times for a class, it won't clobber any previous uses.
    #
    def add_custom_code(declaration, wrapping)
      cache[:declarations] ||= []
      cache[:declarations] << declaration

      cache[:wrappings] ||= []
      cache[:wrappings] << wrapping
    end

    def _get_custom_declarations
      cache[:declarations] || []
    end

    def _get_custom_wrappings
      cache[:wrappings] || []
    end

    # In some cases, the automatic typedef lookup of rb++ can end up
    # doing the wrong thing (for example, it can take a normal class
    # and end up using the typedef for stl::container<>::value_type).
    # Flag a given class as ignoring this typedef lookup if this
    # situation happens.
    def disable_typedef_lookup
      cache[:disable_typedef_lookup] = true
    end

    def _disable_typedef_lookup?
      !!cache[:disable_typedef_lookup]
    end

    # Does this class have virtual methods (especially pure virtual?)
    # If so, then rb++ will generate a proxy class to handle 
    # the message routing as needed.
    def needs_director?
      [methods].flatten.select {|m| m.virtual? }.length > 0
    end

    private

    # Take the cache key, and the normal results, adds to the results
    # those that are in the cache and returns them properly.
    def find_with_cache(type, results)
      in_cache = cache[type]

      ret = QueryResult.new
      ret << results if results
      ret << in_cache if in_cache
      ret.flatten!

      ret.size == 1 ? ret[0] : ret
    end
  end
end

