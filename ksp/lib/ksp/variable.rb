module Ksp
  class Variable
    def self.print_declare(indent, variable)
      variable.each do |statement|
        puts ' ' * indent + statement
      end
    end
  end
end