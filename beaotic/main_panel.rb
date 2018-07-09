module Beaotic
  class MainPanel
    attr_reader :edit_button_dividers,
                :knobs,
                :edit_buttons,
                :edit_button_dividers,
                :title_image,
                :elements

    def initialize(key_group_conf)
      @conf = key_group_conf

      @conf[:knobs].each_index do |index|
        if @conf[:knobs][index][:affected_keys].nil?
          @conf[:knobs][index][:affected_keys] = 0..@conf[:keys].count-1
        end
      end

      @knobs = []
      @edit_buttons = []
      @edit_button_dividers = []
      @main_panel_name = "%panel_main_#{name}"
      @elements = []
      @title_image = Ksp::UiImage.new("title_#{name}", image: "title_#{name}")

      set_knobs
      set_edit_buttons
      set_main_panel_elements
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

    def statements
      statements = ["declare #{@main_panel_name}[#{@elements.count}]"]
      @elements.each_with_index { |elem, idx | statements << "#{@main_panel_name}[#{idx}] := get_ui_id(#{elem})" }
      statements
    end

    def hide
      statements = ["function hide_panel_main_#{name}"]
      @elements.each do |elem|
        statements << "  hide_part(#{elem}, $HIDE_WHOLE_CONTROL)"
      end
      statements << "end function"
    end

    def show
      statements = ["function show_panel_main_#{name}"]
      statements << '  set_skin_offset(0)'
      @elements.each do |elem|
        statements << "  hide_part(#{elem}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
      end
      statements << "end function"
    end

    def set_knobs
      @conf[:knobs].each do |knob_conf|
        knob_identifier = "#{name}_#{knob_conf[:name]}"
        @knobs << Ksp::CustomKnob.new(knob_identifier, knob_conf.merge(key_group_name: name))
        knob_conf[:affected_keys].each do |ak|
          label = "label_#{knob_conf[:name]}"
          @knobs.last.label = Ksp::UiImage.new("label_#{knob_identifier}", image: label)
          @knobs.last.k_groups[:osc1] += @conf[:keys][ak][:k_groups][:osc1]
          if @conf[:keys][ak][:k_groups][:osc2]
            @knobs.last.k_groups[:osc2] += @conf[:keys][ak][:k_groups][:osc2]
          end
        end
        # @knobs.last.set_callback()
      end
    end

    def set_edit_buttons
      @conf[:edit_buttons].each do |k, v|
        button_identifier = "#{name}_#{k}"
        v = v.merge(image: "button_#{k}", key_group_name: name)
        @edit_buttons << Ksp::CustomButton.new(button_identifier, v)

        v = v.merge(image: "img_edit_button_divider", add_to_height: 1)
        divider_identifier = "#{name}_#{k}"
        @edit_button_dividers << Ksp::UiImage.new(divider_identifier, v)
      end
    end
  end
end