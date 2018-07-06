module Beaotic
  class MixPanel
    # attr_reader :statements
    def initialize(name, keys)
      @name = "panel_mix_#{name}"
      @keys = keys
      @channels = []
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
  end
end