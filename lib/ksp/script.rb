module Ksp
  class Script
    attr_accessor(
      :on_init,
      :functions,
      :on_ui_control_callbacks,
      :on_note_callback,
      :on_release_callback,
      :on_controller_callback
    )

    def initialize
      @functions = []
      @on_ui_control_callbacks = []
      @on_note_callback = []
      @on_release_callback = []
      @on_controller_callback = []
    end

    def on_init=(on_init)
      @on_init = ['on init'] + on_init + ['end on']
    end

    def statements
      on_init +
        @functions.map(&:statements) +
        @on_ui_control_callbacks +
        ['on note'] + @on_note_callback + ['end on'] +
        ['on release'] + @on_release_callback + ['end on'] +
        ['on controller'] + @on_controller_callback + ['end on']
    end
  end
end