module Beaotic
  class Instrument
    def initialize(project_name)
      @conf = parse_config("./#{project_name}.yml")
      @debug_file = File.new("./#{project_name}.debug", 'w')
      @key_groups = []
      @on_init = [
          'message("")',
          'make_perfview',
          "set_script_title(\"#{@conf[:global][:project_name]}\")",
          "set_ui_height_px(#{@conf[:global][:perf_view][:height_px]})",
          'set_control_par_str($INST_WALLPAPER_ID, $CONTROL_PAR_PICTURE, "wallpaper")',
          'set_control_par_str($INST_ICON_ID,      $CONTROL_PAR_PICTURE, "img_icon_hejo")',
      ].map { |line|  '  ' + line}
      populate_key_groups
      @script = Ksp::Script.new
      @script.on_init = @on_init
    end

    def populate_key_groups
      @conf[:key_groups].each_with_index do |key_group_conf, idx|
        key_group_conf = key_group_conf.merge(index: idx)
        key_group = Beaotic::KeyGroup.new
        key_group.conf = key_group_conf
        key_group.set_main_panel
        # key_group.set_diode
        # key_group.set_mix_panel
        # key_group.set_keys
        @key_groups << key_group
        @on_init += key_group.statements
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
end