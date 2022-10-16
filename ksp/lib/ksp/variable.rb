module Ksp
  class Variable
    attr_reader :type, :name

    def initialize(type:, name:, persistent: false, args: nil, default_value: nil, arr_length: nil)
      @type = type
      @name = get_name(name)
      @persistent = persistent
      @arr_length = arr_length
      @args = args
      @default_value = default_value
      @custom_statements = []
    end

    def get_name(name)
      case @type
      when 'constant', 'integer', /^ui_+/
        "$#{name}"
      when 'string'
        "@#{name}"
      when 'integer_array'
        "%#{name}"
      when 'string_array'
        "!#{name}"
      else
        ''
      end
    end

    def declare
      case @type
      when 'constant', 'integer', 'string'
        ["declare #{@name}"]
      when /^ui_(button|slider|knob|menu|switch|level_meter|label|file_selector)$/
        args = !@args.nil? && @args.length > 0 ? '(' + @args.join(',') + ')' : ''
        s = ["declare #{@type} #{@name} #{args}"]
        if (@type == 'ui_slider') && !@default_value.nil?
          s << "set_control_par(get_ui_id(#{@name}), $CONTROL_PAR_DEFAULT_VALUE, #{@default_value})"
        end
        s
      when /(integer|string)_array$/
        if @default_value.is_a?(Array) && @arr_length.nil?
          @arr_length = @default_value.count
        end
        ["declare #{@name}[#{@arr_length}]"]
      else
        ['']
      end
    end

    def quote(var)
      if var.is_a?(String)
        "\"#{var}\""
      else
        var
      end
    end

    def assign_default_value
      case @type
      when /(integer|string)_array$/
        if @default_value.nil?
          ""
        else
          @default_value.map.with_index do |element, idx|
            "#{@name}[#{idx}] := #{quote(element)}"
          end.join("\n  ")
        end
      else
        @default_value.nil? ? "" : "#{@name} := #{@default_value}"
      end
    end

    def default_value
      # TODO: Add support for UI controls
      case @type
      when 'constant', 'integer'
        @default_value.to_s
      when 'string'
        "\"#{default_value}\""
      when 'integer_array'
        '[' + @default_value.join(',') + ']'
      when 'string_array'
        '[' + @default_value.map{ |element| "\"#{element}\"" } .join(',') + ']'
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
      declare + [
          assign_default_value,
          persist
      ]
    end
  end
end