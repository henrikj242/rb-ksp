module Ksp
  class Utility
    def self.get_conf(path)
      parse_config("./#{project_name}.yml")
    end

    def self.prepare_out_folders(project_name)
      %w[scripts pictures].each do |r|
        FileUtils.mkdir_p("./out/#{project_name}/Resources/#{r}")
      end
      FileUtils.mkdir_p("./out/_debug")
    end

    # symbolize function Grapped from https://gist.github.com/Integralist/9503099
    # modified by myself to support Ranges
    def self.symbolize(obj)
      return obj.reduce({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = symbolize(v) }
      end if obj.is_a? Hash

      return obj.reduce([]) do |memo, v|
        memo << symbolize(v); memo
      end if obj.is_a? Array

      return obj.to_a.reduce([]) do |memo, v|
        memo << symbolize(v); memo
      end if obj.is_a? Range

      obj
    end

    def self.parse_config(conf_file)
      symbolize(YAML::load_file(conf_file))
    end

    HALF_TONE = 13888.888888888889

  end

  class AutomationIdCounter
    @@current = 0
    def self.next
      @@current += 1
    end
  end
end

# Monkey patches
class Array
  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary || [object]
    else
      [object]
    end
  end
end

