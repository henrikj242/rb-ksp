class String
  def labelize
    gsub('_', "\n").upcase
  end
end

module Beaotic
  class Wallpaper
    require "mini_magick"

    FONT = 'BebasNeue Bold.ttf'.freeze
    # TEXT_COLOR = '#E5E5E5'.freeze
    TEXT_COLOR = '#D6D6D6'.freeze

    def initialize(project_name)
      @project_name = project_name
      @conf = Beaotic.parse_config("./#{project_name}.yml")
      @gui_directory = '_gui'
    end

    def main_panel(key_group_conf)
      wallpaper = MiniMagick::Image.new("#{@gui_directory}/wallpaper_main.png")
      title = MiniMagick::Image.new("#{@gui_directory}/title_#{key_group_conf[:name]}.png")
      labels = key_group_conf[:knobs].map.with_index do |knob, idx|
        {
          txt:  knob[:name].labelize,
          x:    (knob[:position] ? 5 + (knob[:position][0] * 78) : 5 + (idx * 78)) - 279
        }
      end
      dividers = key_group_conf[:edit_buttons].map.with_index do |button, idx|
        {
          img:  MiniMagick::Image.new("#{@gui_directory}/img_edit_button_divider.png"),
          x:    65 + (idx * 51)
        }
      end
      wallpaper = wallpaper.composite(title) do |c|
        c.compose   "Over"
        c.geometry  "+83+69"
      end
      labels.each do |e|
        wallpaper = wallpaper.combine_options do |c|
          c.gravity   'south'
          c.font      FONT
          c.pointsize '14'
          c.fill(TEXT_COLOR)
          c.draw      "text #{e[:x]},276 '#{e[:txt]}'"
        end
      end
      dividers.each do |e|
        wallpaper = wallpaper.composite(e[:img]) do |c|
          c.compose   "Over"
          c.geometry  "+#{e[:x]}+248"
        end
      end

      filename = "#{@gui_directory}/im_wallpaper_main_#{key_group_conf[:name]}.png"
      wallpaper.write(filename)
      filename
    end

    def mix_panel(key_group_conf)
      wallpaper = MiniMagick::Image.new("#{@gui_directory}/wallpaper_mix.png")

      pitch_labels = key_group_conf[:keys].map.with_index do |key, idx|
        {
            txt:  'PITCH',
            x:    (idx * 78) - 196,
            y:    310
        }
      end

      frames = key_group_conf[:keys].map.with_index do |_, idx|
        {
            img: MiniMagick::Image.new("#{@gui_directory}/frame_channel.png"),
            x: 81 + (idx * 78)
        }
      end
      titles = key_group_conf[:keys].map.with_index do |key, idx|
        {
          img: MiniMagick::Image.new("#{@gui_directory}/title_mix_#{key_group_conf[:name]}_#{key[:name]}.png"),
          x: 82 + (idx * 78)
        }
      end
      # labels = key_group_conf[:keys].map.with_index do |key, idx|
      #   [
      #     {
      #       img: MiniMagick::Image.new("#{@gui_directory}/label_mix_pitch.png"),
      #       x: 82 + (idx * 78) + 2,
      #       y: 90
      #     },
      #     {
      #       img: MiniMagick::Image.new("#{@gui_directory}/label_mix_level.png"),
      #       x: 82 + (idx * 78) + 8,
      #       y: 200
      #     },
      #     {
      #       img: MiniMagick::Image.new("#{@gui_directory}/label_mix_pan.png"),
      #       x: 82 + (idx * 78) + 48,
      #       y: 200
      #     }
      #   ]
      # end
      frames.drop(1).each do |e|
        wallpaper = wallpaper.composite(e[:img]) do |c|
          c.compose   "Over"
          c.geometry  "+#{e[:x]}+96"
        end
      end
      titles.each do |e|
        wallpaper = wallpaper.composite(e[:img]) do |c|
          c.compose   "Over"
          c.geometry  "+#{e[:x]}+70"
        end
      end
      pitch_labels.each do |e|
        wallpaper = wallpaper.combine_options do |c|
          c.gravity   'south'
          c.font      FONT
          c.kerning   '1'
          c.pointsize '12'
          c.fill(TEXT_COLOR)
          c.draw      "text #{e[:x]},#{e[:y]} '#{e[:txt]}'"
        end
      end

      # labels.each do |label_set|
      #   label_set.each do |e|
      #     wallpaper = wallpaper.composite(e[:img]) do |c|
      #       c.compose   "Over"
      #       c.geometry  "+#{e[:x]}+#{e[:y]}"
      #     end
      #   end
      # end

      filename = "#{@gui_directory}/im_wallpaper_mix_#{key_group_conf[:name]}.png"
      wallpaper.write(filename)
      filename
    end

    def key_group(key_group_conf)
      {
        main: main_panel(key_group_conf),
        mix: mix_panel(key_group_conf)
      }
    end

    def instrument
      @key_groups = []
      @conf[:key_groups].each do |key_group_conf|
        @key_groups << key_group(key_group_conf)
        break
      end
      MiniMagick::Tool::Convert.new do |convert|
        convert.append.-
        @key_groups.each do |key_group_wallpapers|
          convert << key_group_wallpapers[:main]
          convert << key_group_wallpapers[:mix]
        end
        convert << "#{@gui_directory}/wallpaper_#{@project_name}.png"
      end
    end
  end
end