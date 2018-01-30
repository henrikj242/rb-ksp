def symbolize(obj)
  return obj.reduce({}) do |memo, (k, v)|
    memo.tap { |m| m[k.to_sym] = symbolize(v) }
  end if obj.is_a? Hash
    
  return obj.reduce([]) do |memo, v| 
    memo << symbolize(v); memo
  end if obj.is_a? Array
  
  obj
end

def parse_config(config_file = 'ksp.yml')
	y = YAML::load_file(File.join(__dir__, 'ksp.yml'))
	symbolize(y)
end
