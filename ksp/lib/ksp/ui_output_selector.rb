module Ksp
  class UiOutputSelector < UiMenu
    def populate
      [
        "$i := 0",
        "while ($i < $NUM_OUTPUT_CHANNELS)",
        "  add_menu_item(#{name}, output_channel_name($i), $i)",
        "  inc($i)",
        "end while"
      ]
    end

    def statements
      super + populate
    end
  end
end