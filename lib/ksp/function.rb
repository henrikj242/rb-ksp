module Ksp
  class Function
    attr_reader :body, :name

    def initialize(name)
      @name = name
      @body = []
    end

    def set_body(body_statements = [])
      @body = body_statements
      self
    end

    def append(body_statements = [])
      if body_statements.is_a? Array
        @body += body_statements
      elsif body_statements.is_a? String
        @body << body_statements
      end
      self
    end

    def statements
      ["function #{@name}"] +
          @body.map { |line| '  ' + line } +
          ['end function']
    end
  end
end