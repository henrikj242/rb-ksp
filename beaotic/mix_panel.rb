module Beaotic
  class MixPanel
    attr_reader :channels, :name, :functions
    def initialize(conf)
      @conf = conf
      @name = "panel_mix_#{@conf[:name]}"
      @keys = @conf[:keys]
      @skin_offset = @conf[:skin_offsets][@conf[:keys].count]
      @channels = set_channels
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
      channels = []
      @keys.each_with_index do |key, idx|
        ch_base_x = 80 + (idx * 76)
        channels << MixChannel.new(key, ch_base_x)
      end
      channels
    end

    def init
      statements = ["{ I am the Mix Panel }"]
      @channels.each { |ch| ch.statements.each { |statement| statements << statement } }
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
      f.set_body(['set_skin_offset(0)'])
      @channels.each do |channel|
        channel.elements.each do |element|
          f.append([element.show])
        end
      end
      f
    end
  end
end