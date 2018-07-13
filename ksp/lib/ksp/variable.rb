module Ksp
  class Variable
    attr_reader :type, :name

    def initialize(
        type: '',
        name: '',
        persistent: false,
        args: nil,
        default_value: nil,
        arr_length: nil
    )
      @type = type.to_s
      @name = name(name)
      @persistent = !!persistent
      @arr_length = arr_length
      @args = args
      @default_value = default_value
    end

    def name(name)
      case @type
      when 'constant', 'integer', /ui_+/
        "$#{name}"
      when 'string'
        "@#{name}"
      when 'integer_array'
        "%#{name}"
      when 'string_array'
        "!#{name}"
      else ''
        ''
      end
    end

    def declare
      case @type
      when 'constant', 'integer', 'string'
        "declare #{@name}"
      when /^ui_(button|slider|knob|menu|switch|level_meter|label|file_selector)$/
        args = !@args.nil? && @args.length > 0 ? '(' + @args.join(',') + ')' : ''
        "declare #{@type} #{@name} #{args}"
      when /(integer|string)_array$/
        "declare #{@name}[#{@arr_length}]"
      else
        ''
      end
    end

    def assign_default_value
      @default_value.nil? ? "" : "#{@name} := #{@default_value}"
    end

    def default_value
      # TODO: Add support for UI controls
      case @type
      when 'constant', 'integer'
        @default_value
      when 'string'
        "\"#{default_value}\""
      when 'integer_array'
        '[' + @default_value.join(',') + ']'
      when 'string_array'
        '[' + @default_value.map{ |element| "\"#{element}\"" } .join(',') + ']'
      end
    end

    def self.print_declare(indent, variable)
      variable.each do |statement|
        puts ' ' * indent + statement
      end
    end

    def name=(name)
      @name = name
    end

    def persistent?
      @persistent
    end

    def persist
      if persistent?
        "make_persistent(#{@name})"
      else
        ""
      end
    end

    def statements
      [
          declare,
          assign_default_value,
          persist
      ]
    end
  end
end