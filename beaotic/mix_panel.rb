module Beaotic
  class MixPanel
    attr_reader :statements
    def initialize()
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

      @statements = ["{ I am the Mix Panel }"]
    end
  end
end