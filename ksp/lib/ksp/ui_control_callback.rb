module Ksp
  class UiControlCallback
    attr_accessor :body

    def initialize(ui_control_name)
      @ui_control_name = ui_control_name
      @body = []
    end

    def statements
      ["on ui_control(#{@ui_control_name})"] +
          @body.map { |line| '  ' + line } +
          ['end on']
    end
  end
end