module Ksp
  class Instrument
    attr_accessor :on_init, :functions
    def initialize(cfg)
      @project_name = cfg[:global][:project_name]
      @script = Ksp::Script.new
      @conf = cfg
      @debug_file = File.new("./out/_debug/#{@project_name}.debug", 'w')
      @output_file = File.new("./out/#{project_name}/Resources/scripts/#{@project_name}.txt", 'w')
    end

    def compile
      @script.on_init = on_init
      @script.functions = functions
      @script.on_ui_control_callbacks = on_ui_control_callbacks
      @script.on_note_callback = on_note_callback
      @script.on_release_callback = on_release_callback
      @script.on_controller_callback = on_controller_callback
    end

    def on_init
      []
    end

    def functions
      []
    end

    def on_note_callback
      []
    end

    def on_release_callback
      []
    end

    def on_controller_callback
      []
    end

    def on_ui_control_callbacks
      []
    end
    alias_method :on_ui_control_callback, :on_ui_control_callbacks

    def print
      statements.each { |statement| @output_file.puts statement }
    end

    def statements
      @script.statements
    end

    def var_dump
      @debug_file.puts "# [DEBUG] @conf { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp @conf, @debug_file

      # @debug_file.puts '*' * 80
      # @debug_file.puts "# [DEBUG] @key_groups { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      # PP::pp @key_groups, @debug_file

      @debug_file.puts '*' * 80
      @debug_file.puts "# [DEBUG] statements { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp statements, @debug_file
    end
  end
end