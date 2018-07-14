module Beaotic
  class MixChannel
    attr_reader :elements
    def initialize(conf, idx)
      @conf = conf
      @name = conf[:name]
      @base_x = 80 + (idx * 76)
      # set_elements
    end

    def set_title_image
      @title_image = Ksp::UiImage.new("title_mix_#{@name}")
    end

    def statements
      statements = @title_image.declare
      statements << @title_image.set_position(@base_x + 5, 0)
      statements
    end

    def set_elements
      set_title_image
      @elements = [
          @title_image
      ]
    end
  end
end