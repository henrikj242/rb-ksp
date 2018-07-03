module Beaotic
  class Image
    def initialize(conf)
      @conf = conf
      @directory = '_gui'
    end

    def generate_txt_files
      image_file_names.each do |name|
        image_type = name.split('_').first
        content = content(image_type)
        if content.length > 0
          File.open("#{@directory}/#{name}.txt", 'w') do |f|
            f.write(content)
          end
        end
      end
    end

    def image_file_names
      image_file_names = []
      Dir.foreach(@directory) do |item|
        next if item == '.' or item == '..'
        if item.match(/\.txt/)
          File.unlink("#{@directory}/#{item}")
        elsif item.match(/\.png/)
          image_file_names << File.basename(item, '.png')
        end
      end
      image_file_names
    end

    def content(image_type)
      content_hash = case image_type
                     when 'img'
                       template vertical_resizable: 'yes',
                                horizontal_resizable: 'yes',
                                number_of_animations: 1
                     when 'title', 'label'
                       template number_of_animations: 1
                     when 'diode'
                       template number_of_animations: 3
                     when 'button'
                       template number_of_animations: 6
                     when 'fader'
                       template number_of_animations: 41
                     when 'knob'
                       template number_of_animations: 101
                     when 'wallpaper'
                       template number_of_animations: @conf[:wallpaper_animations]
                     else
                       {}
                     end
      output = ''
      content_hash.map do |k, v|
        output << k.to_s.split('_').map do |word|
          if %w(of).include?(word)
            word
          else
            word.capitalize
          end
        end.join(' ') + ": #{v}\n"
      end
      output
    end

    def template(options = {})
      {
          has_alpha_channel: options[:has_alpha_channel] || 'yes',
          number_of_animations: options[:number_of_animations] || 1,
          horizontal_animation: options[:horizontal_animation] || 'no',
          vertical_resizable: options[:vertical_resizable] || 'no',
          horizontal_resizable: options[:horizontal_resizable] || 'no',
          fixed_top: options[:fixed_top] || 0,
          fixed_bottom: options[:fixed_bottom] || 0,
          fixed_left: options[:fixed_left] || 0,
          fixed_right: options[:fixed_right] || 0,
      }
    end
  end
end