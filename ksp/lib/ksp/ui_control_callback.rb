module Ksp
  class UiControlCallback
    attr_accessor :body

    def initialize(ui_control)
      @ui_control = ui_control
      @body = []
    end

    def statements
      ["on ui_control(#{@ui_control.name})"] +
          @body.map { |line| '  ' + line } +
          ['end on']
    end
  end
end