module Beaotic
  class MixPanel
    attr_reader :channels, :name
    def initialize(name, keys, skin_offset)
      @name = "panel_mix_#{name}"
      @keys = keys
      @channels = []
      @skin_offset = skin_offset
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

    def set_channels
      @keys.each_with_index do |key, idx|
        @channels << MixChannel.new(key, idx)
      end
    end

    def statements
      statements = ["{ I am the Mix Panel }"]
      @channels.each { |ch| ch.statements.each { |statement| statements << statement } }
      statements
    end

    def show
      statements = ["function show_#{name}"]
      statements << "  set_skin_offset(#{@skin_offset})"
      @channels.each do |channel|
        channel.elements.each do |elem|
          statements << "  hide_part(#{elem.name}, $HIDE_PART_BG .or. $HIDE_PART_MOD_LIGHT .or. $HIDE_PART_TITLE .or. $HIDE_PART_VALUE)"
        end
      end
      statements << "end function"
    end

    def hide
      statements = ["function hide_#{name}"]
      @channels.each do |channel|
        channel.elements.each do |elem|
            statements << "  hide_part(#{elem.name}, $HIDE_WHOLE_CONTROL)"
        end
      end
      statements << "end function"
    end
  end
end