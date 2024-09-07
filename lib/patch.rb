class GCCXML
  def parse(header_file, to_file)
    includes = @includes.flatten.uniq.map {|i| "-I#{i.chomp}"}.join(" ").chomp
    flags = @flags.flatten.join(" ").chomp
    flags += " -Wno-unused-command-line-argument --castxml-cc-gnu gcc #{find_clang} --castxml-gccxml"

    exe = find_exe.strip.chomp
    cmd = "#{exe} #{includes} #{flags} -o #{to_file} #{header_file}"
    raise "Error executing castxml command line: #{cmd}" unless system(cmd)
  end
end

module RbGCCXML
  class Type
    def check_sub_type_without(val, delim)
      if val.is_a?(String)
        return false unless val =~ delim
        new_val = val.gsub(delim, "").strip
      elsif val.is_a?(RbGCCXML::PointerType)
        # Handle PointerType objects
        new_val = val.base_type
      else
        return false
      end

      base_type = NodeCache.find(attributes["type"])
      base_type == new_val

    rescue Exception => e
      binding.pry
    end
  end
end