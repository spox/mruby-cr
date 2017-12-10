require 'ffi_gen'

class FFIGen

  # Define simple types
  SIMPLE_TYPES = {
    void: 'Void',
    bool: 'Bool',
    u_char: 'UInt8',
    u_short: 'UInt16',
    u_int: 'UInt16',
    u_long: 'UInt32',
    u_long_long: 'UInt64',
    char_s: 'UInt8',
    s_char: 'UInt8',
    short: 'Int16',
    int: 'Int16',
    long: 'Int32',
    long_long: 'Int64',
    float: 'Float32',
    double: 'Float64',
  }

  class Name
    CRYSTAL_KEYWORDS = [
      "BEGIN",
      "END",
      "alias",
      "and",
      "begin",
      "break",
      "case",
      "class",
      "def",
      "defined",
      "do",
      "else",
      "elsif",
      "end",
      "ensure",
      "false",
      "for",
      "if",
      "in",
      "module",
      "next",
      "nil",
      "not",
      "or",
      "redo",
      "rescue",
      "retry",
      "return",
      "self",
      "super",
      "then",
      "true",
      "undef",
      "unless",
      "until",
      "when",
      "while",
      "yield",
    ]

    def to_crystal_downcase
      fix_empty_prefix
      format :downcase, :underscores, CRYSTAL_KEYWORDS
    end

    def to_crystal_classname
      fix_empty_prefix
      format :camelcase, CRYSTAL_KEYWORDS
    end

    def to_crystal_constant
      fix_empty_prefix
      format :upcase, :underscores, CRYSTAL_KEYWORDS
    end

    def fix_empty_prefix
      if @parts.empty?
        @parts = @raw.split(
          /_|(?=[A-Z][a-z])|(?<=[a-z])(?=[A-Z])/
        ).reject(&:empty?)
      end
    end
  end

  class Enum
    def write_crystal(writer)
      if @constants.empty?
        writer.puts "alias #{crystal_name} = Void*", ""
      else
        writer.puts "enum #{crystal_name}"
        writer.indent do
          writer.write_array @constants do |constant|
            "#{constant[:name].to_crystal_classname} = #{constant[:value]}"
          end
        end
        writer.puts "end", ""
      end
    end

    def crystal_name
      @name.to_crystal_classname
    end
  end

  class StructOrUnion
    def write_crystal(writer)
      if @fields.empty?
        writer.puts "alias #{crystal_name} = Void*", ""
      else
        writer.puts "#{@is_union ? 'union' : 'struct'} #{crystal_name}"
        writer.indent do
          @fields.each do |field|
            writer.puts "#{field[:name].to_crystal_downcase}: " \
                        "#{@generator.to_crystal_type field[:type]}"
          end
        end
        writer.puts "end", ""
      end
    end

    def crystal_name
      @crystal_name ||= @name.to_crystal_classname
    end
  end

  class FunctionOrCallback
    def write_crystal(writer)
      params = @parameters.map do |parameter|
        type = @generator.to_crystal_type parameter[:type]
        name = if !parameter[:name].empty?
                 parameter[:name].to_crystal_downcase
               else
                 type.gsub('*', '').downcase
               end
        "#{name} : #{type}"
      end

      writer.puts "fun #{crystal_name} = \"#{raw_name}\"(#{params.join(', ')}) " \
                  ": #{@generator.to_crystal_type @return_type}"
    end

    def crystal_name
      @crystal_name ||= @name.to_crystal_downcase
    end

    def raw_name
      @raw_name ||= @name.raw
    end
  end

  class Constant
    def write_crystal(writer)
      writer.puts "#{@name.to_crystal_constant} = #{@value}"
    end
  end

  # Entry point for generation
  def generate_cr
    writer = Writer.new "  ", "# "
    writer.puts "@[Link(ldflags: \"-L#{$opts[:mruby_libdir]} -l#{@ffi_lib} -lm\")]"
    writer.puts "lib #{@module_name}"
    defs = collect_defs
    defs.keys.each do |key|
      defs[key].each do |d|
        if d.respond_to?(:write_crystal)
          d.write_crystal(writer)
        end
      end
    end
    writer.puts "end"
    writer.output
  end

  def collect_defs
    {}.tap do |defs|
      declarations.values.compact.uniq.each do |declaration|
        defs[declaration.class] ||= []
        defs[declaration.class] << declaration
      end
    end
  end

  def to_crystal_type(type)
    ctype = Clang.get_canonical_type(type)
    kind = ctype[:kind]
    if SIMPLE_TYPES[kind]
      SIMPLE_TYPES[kind]
    else
      case ctype[:kind]
      when :pointer
        ptype = Clang.get_pointee_type(ctype)
        result = SIMPLE_TYPES[ptype[:kind]]
        if result
          result += '*'
        else
          case ptype[:kind]
          when :record
            pdecl = declarations[Clang.get_cursor_type(
                                   Clang.get_type_declaration(ptype)
                                 )]
            result = pdecl ? "#{pdecl.crystal_name}*" : "Void*"
          when :function_proto
            declaration = declarations[type]
            result = "Void*"
          else
            pdepth = 0
            ptarget = ""
            current_t = type
            while ptarget.empty?
              decl = Clang.get_type_declaration(current_t)
              ptarget = Name.new(self,
                                 Clang.get_cursor_spelling(decl).to_s_and_dispose)
              break unless ptarget.empty?
              case current_t[:kind]
              when :unexposed
                break
              when :pointer
                pdepth += 1
                current_t = Clang.get_pointee_type(current_t)
              else
                ptarget = Name.new(self,
                                   Clang.get_type_kind_spelling(
                  current_t[:kind]
                ).to_s_and_dispose)
                break
              end
            end
            decl_key = Clang.get_cursor_type(
              Clang.get_type_declaration(current_t)
            )
            if declarations[decl_key]
              result = "#{ptarget.to_crystal_classname}#{'*' * pdepth}"
            else
              result = "Void#{'*' * pdepth}"
            end
          end
        end
        result
      when :enum, :record
        declarations[ctype]&.crystal_name || "Int32"
      when :constant_array
        tdata = to_crystal_type(
          Clang.get_array_element_type(ctype)
        )
        size = Clang.get_array_size(ctype)
        "StaticArray(#{tdata}, #{size})"
      else
        raise NotImplementedError.new("Cannot translate #{kind}")
      end
    end
  end
end
