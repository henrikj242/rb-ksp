module Beaotic
  class MixPanel
    attr_reader :channels, :name, :functions
    def initialize(conf)
      @conf = conf
      @name = "panel_mix_#{@conf[:name]}"
      @keys = @conf[:keys]
      @skin_offset = @conf[:skin_offsets][@keys.count]
      set_channels
      # @volume_faders = []
      # @pan_faders = []
      # @pitch_knobs = []
      # @conf[:keys].each do |key_conf|
      #   @volume_faders << Ksp::VolumeFader.new(name, key_conf)
      # @pan_faders << PanFader.new(name, key_conf)
      # pitch knob
      # output menu
      # diode
      # end

    end

    def set_functions
      @functions = [hide, show]
    end

    def set_channels
      @channels = []
      @keys.each_with_index do |key, idx|
        ch = MixChannel.new(key[:name], 82 + (idx * 78))
        ch.elements = [
            ch.set_title_image,
            ch.set_pitch_knob(-200000, 0, 200000),
            ch.set_level_knob(-100, 0, 100),
            ch.set_pan_knob(-100, 0, 100),
            ch.set_pitch_mode_button
        ]
        @channels << ch
      end
    end

    def init
      statements = ["{ I am the Mix Panel }"]
      @channels.each do |ch|
        ch.elements.each do |element|
          statements += element.statemens
        end
      end
      # @channels.each { |ch| ch.statements.each { |statement| statements << statement } }
      statements
    end

    def hide
      f = Ksp::Function.new("hide_#{name}")
      @channels.each do |channel|
        channel.elements.each do |element|
          f.append ([element.hide])
        end
      end
      f
    end

    def show
      f = Ksp::Function.new("show_#{name}")
      f.set_body(["set_skin_offset(#{@skin_offset})"])
      @channels.each do |channel|
        channel.elements.each do |element|
          f.append([element.show])
          # f.append(["hide_part(#{element.name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"])
        end
      end
      f
    end
  end
end