module Beaotic
  class MixChannel
    def initialize(conf, idx)
      @conf = conf
      @name = conf[:name]
      @base_x = 30 + (idx * 50)
      set_elements
    end

    def set_title_image
      # title_mix_clp_2
      @title_image = Ksp::UiImage.new("title_mix_#{@name}")
    end

    def statements
      statements = @title_image.declare
      statements << @title_image.set_position(@base_x + 5, 5)
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