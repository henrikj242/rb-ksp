module Ksp
  class Integer < Variable
    def self.declare(name, init_val)
      "declare #{name} := #{init_val}"
    end
  end
end
