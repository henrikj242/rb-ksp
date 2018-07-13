module Beaotic
  class Instrument
    def initialize(project_name)
      @conf = parse_config("./#{project_name}.yml")
      @debug_file = File.new("./#{project_name}.debug", 'w')
      @script = Script.new(@conf)

      @key_groups = []
      populate_key_groups(@script)
    end

    def populate_key_groups(script)
      @conf[:key_groups].each_with_index do |key_group_conf, idx|
        key_group_conf = key_group_conf.merge(index: idx)
        @key_groups << Beaotic::KeyGroup.new(key_group_conf)
      end
      @key_groups.each do |key_group|
        script.on_init += key_group.statements
      end
    end

    def print
      statements.each { |statement| puts statement }
    end

    def statements
      @script.statements
    end

    def var_dump
      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp @conf, @debug_file

      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp @key_groups, @debug_file

      @debug_file.puts "# [DEBUG] { Created by: #{ENV['USER'] || ENV['USERNAME']} at #{Time.now} }"
      PP::pp statements, @debug_file
    end

    # symbolize function Grapped from https://gist.github.com/Integralist/9503099
    # modified by myself to support Ranges
    def symbolize(obj)
      return obj.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = symbolize(v) }
      end if obj.is_a? Hash

      return obj.reduce([]) do |memo, v|
        memo << symbolize(v); memo
      end if obj.is_a? Array

      return obj.to_a.reduce([]) do |memo, v|
        memo << symbolize(v); memo
      end if obj.is_a? Range

      obj
    end

    def parse_config(conf_file)
      symbolize(YAML::load_file(conf_file))
    end

  end

  class Script
    attr_accessor(
      :on_init,
      :functions,
      :on_ui_control_callbacks,
      :on_note_callback,
      :on_release_callback
    )
    attr_reader :conf

    def initialize(conf)
      @conf = conf
      @on_init = [
          'message("")',
          'make_perfview',
          "set_script_title(\"#{conf[:global][:project_name]}\")",
          "set_ui_height_px(#{@conf[:global][:perf_view][:height_px]})",
          'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")',
          'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "img_icon_hejo")',
      ].map { |line|  '  ' + line}
      @functions = []
      @on_ui_control_callbacks = []
      @on_note_callback = []
      @on_release_callback = []
    end

    def statements
      ['on init'] + @on_init + ['end on'] +
      @functions.map(&:statements) +
      @on_ui_control_callbacks.map(&:statements) +
      ['on note'] + @on_note_callback + ['end on'] +
      ['on release'] + @on_release_callback + ['end on']
    end
  end
end