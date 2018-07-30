module Beaotic
  class MainPanel
    attr_reader :edit_button_dividers,
                :knobs,
                :edit_buttons,
                :edit_button_dividers,
                :title_image,
                :elements,
                :functions

    def initialize(key_group_conf)
      @conf = key_group_conf

      # affect all keys/oscs if none specified
      @conf[:knobs].each_index do |index|
        if @conf[:knobs][index][:affected_keys].nil?
          @conf[:knobs][index][:affected_keys] = 0..@conf[:keys].count-1
        end
        if @conf[:knobs][index][:affected_oscs].nil?
          @conf[:knobs][index][:affected_oscs] = %w[osc1 osc2]
        end
      end

      @knobs = []
      @edit_buttons = []
      @edit_button_dividers = []
      @main_panel_name = "%panel_main_#{name}"
      @elements = []
      @title_image = Ksp::UiImage.new(
        name:     "title_#{name}",
        picture:  "title_#{name}"
      )
      @title_image.xy(82, 0)
      @ui_control_callbacks = []
    end

    def name
      @conf[:name]
    end

    def set_main_panel_elements
      @elements = @knobs.map(&:name) +
          @knobs.map{ |knob| knob.label.name if knob.label } +
          @edit_buttons.map(&:name) +
          @edit_button_dividers.map(&:name)
      @elements << @title_image.name
    end

    def set_functions
      @functions = [hide, show]
    end

    def hide
      f = Ksp::Function.new("hide_panel_main_#{name}")
      f.append(
          @elements.map do |element|
            "hide_part(#{element}, $HIDE_WHOLE_CONTROL)"
          end
      )
    end

    def show
      f = Ksp::Function.new("show_panel_main_#{name}")
      f.set_body(['set_skin_offset(0)'])
      f.append(
          @elements.map do |element|
            "hide_part(#{element}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
          end
      )
    end

    def set_knobs
      y = 84
      @conf[:knobs].each_with_index do |knob_conf, idx|
        knob = Beaotic::Knob.new(
            name: "#{name}_#{knob_conf[:name]}",
            diameter: 48,
            label: knob_conf[:name],
            min_val: knob_conf[:min_val],
            default_val: knob_conf[:default_val],
            max_val: knob_conf[:max_val],
            mouse_behaviour: knob_conf[:ui_control][:mouse_behaviour],
            visible: name == 'bd'
        )
        x = knob_conf[:position] ?
                19 + (knob_conf[:position][0] * 78) :
                19 + (idx * 78)
        knob.xy(x, y)
        knob.label_offset
        knob.add_callbacks(ui_control_callbacks(knob, knob_conf))
        @knobs << knob
      end
    end

    def ui_control_callbacks(ui_control, conf)
      return unless conf[:trigger_on] == 'ui_control'
      statements = []
      if conf[:function] == 'inline'
        conf[:affected_keys].each do |aff_key_idx|
          @conf[:keys][aff_key_idx][:k_groups].each do |osc, k_groups|
            k_groups.each do |k_group|
              if conf[:modulator]
                modulator = "  find_mod(#{k_group},\"#{conf[:modulator]}\")"
              else
                modulator = "  -1"
              end
              if conf[:affected_oscs].include? osc.to_s
                statements << "  set_engine_par(#{conf[:parameter]}, #{ui_control.name}, #{k_group}, #{modulator}, -1)"
              end
            end
          end
        end
      elsif conf[:function] =~ /KEY_GROUP/
        statements << "  call #{conf[:function].sub(/KEY_GROUP/, name)}"
      end
      if conf[:call]
        conf[:call].each { |call| statements << "  call #{call.sub(/KEY_GROUP/, name)}" }
      end
      statements
    end

    def set_edit_buttons
      y = 179
      idx = 0
      @conf[:edit_buttons].each do |button_name, button_conf|
        @edit_buttons << Beaotic::Button.new(
          name:     "button_#{name}_#{button_name}",
          picture:  "button_#{button_name}"
        )
        @edit_buttons.last.xy(18 + (idx * 51), y)
        @edit_buttons.last.add_callbacks(ui_control_callbacks(@edit_buttons.last, button_conf))

        @edit_button_dividers << Ksp::UiImage.new(
          picture: 'img_edit_button_divider',
          name:     "img_#{name}_#{button_name}_divider"
        )
        @edit_button_dividers.last.set_dimensions(add_to_height: 1)
        @edit_button_dividers.last.xy(65 + (idx * 51), y)

        idx += 1
      end
    end
  end
end