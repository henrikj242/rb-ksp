module Ksp
  class UiMenu < UiControl
    def initialize(
        name:,
        persistent:         true,
        visible:            true,
        picture:            'menu',
        default_value:      nil,
        default_value_name: nil,
        text_alignment:     1,
        font_type:          4,
        help_text:          nil
    )
      super(
          type:           'ui_menu',
          name:           name,
          persistent:     persistent,
          default_value:  default_value,
          visible:        visible,
          picture:        picture,
          help_text:      help_text
      )

      @menu_items = []
      @text_alignment = text_alignment
      @font_type = font_type
      add_menu_items(
        [
          {
            default_value_name.to_s => default_value
          }
        ]
      ) if default_value && default_value_name
    end

    def add_menu_items(items = [])
      @menu_items += items
    end

    # item must be a single element hash with one string key and one integer value, i.e.
    # { "str_display" => int_value }
    def add_menu_item_runtime(item)
      "add_menu_item(#{name}, \"#{item.keys.first}\", #{item.values.last})"
    end

    def statements
      statements = super + [
        "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_TEXTPOS_Y, 0)",
        "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_TEXT_ALIGNMENT, #{@text_alignment})",
        "set_control_par(get_ui_id(#{name}), $CONTROL_PAR_FONT_TYPE, #{@font_type})"
      ]
      if @menu_items.count > 0
        @menu_items.map do |item|
          statements << add_menu_item_runtime(item)
        end
      end
      statements
    end
    alias_method :on_init, :statements
  end
end