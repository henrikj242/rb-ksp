# symbolize function Grapped from https://gist.github.com/Integralist/9503099
# modified by myself to support Ranges
def symbolize(obj)
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

def parse_config(conf_file)
  symbolize(YAML::load_file(conf_file))
end

def yaml_file(filename)
  "#{filename}.yml"
end

def text_file(filename)
  "#{filename}.txt"
end
