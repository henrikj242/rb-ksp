module Ksp
  class Function
    attr_reader :body

    def initialize(name)
      @name = name
      @body = []
    end

    def set_body(body_statements = [])
      @body = body_statements
      self
    end

    def append(body_statements = [])
      @body += body_statements
      self
    end

    def statements
      ["function #{@name}"] +
          @body.map { |line| '  ' + line } +
          ['end function']
    end
  end
end