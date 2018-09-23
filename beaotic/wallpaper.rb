class String
  def labelize
    gsub('_', (length > 7 ? "\n" : ' ' )).upcase
  end
end

module Beaotic
  class Wallpaper
    require "mini_magick"

    FONT        = 'BebasNeue Bold.ttf'.freeze
    TEXT_COLOR  = '#D6D6D6'.freeze
    TITLE_COLOR = '#6E8FD6'.freeze

    def initialize(project_name)
      @project_name   = project_name
      @conf           = Beaotic.parse_config("./#{project_name}.yml")
      @gui_directory  = '_gui/wallpaper_elements'
      @tmp_prefix     = '__im_beaotic__'
      @tmp_files      = []
    end

    def main_panel(key_group_conf)
      wallpaper = MiniMagick::Image.open("#{@gui_directory}/wallpaper_#{@project_name}_main.png")

      wallpaper = wallpaper.combine_options do |c|
        c.gravity   'north'
        c.font      FONT
        c.kerning   '1'
        c.pointsize '14'
        c.fill(TITLE_COLOR)
        c.draw      "text 0,69 '#{key_group_conf[:title]}'"
      end

      labels = key_group_conf[:knobs].map.with_index do |knob, idx|
        {
          txt:  knob[:name].labelize,
          x:    (knob[:position] ? 5 + (knob[:position][0] * 78) : 5 + (idx * 78)) - 279
        }
      end
      dividers = key_group_conf[:edit_buttons].map.with_index do |_button, idx|
        {
          img:  MiniMagick::Image.open("#{@gui_directory}/edit_button_divider.png"),
          x:    65 + (idx * 51)
        }
      end

      labels.each do |e|
        wallpaper = wallpaper.combine_options do |c|
          c.gravity   'south'
          c.font      FONT
          c.kerning   '1'
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

      filename = "#{@gui_directory}/#{@tmp_prefix}wallpaper_main_#{key_group_conf[:name]}.png"
      wallpaper.write(filename)
      @tmp_files << filename
      filename
    end

    def mix_panel(key_group_conf)
      wallpaper = MiniMagick::Image.open("#{@gui_directory}/wallpaper_#{@project_name}_mix.png")

      labels = key_group_conf[:keys].map.with_index do |key, idx|
        {
          title: {
              txt:  key[:name].to_s.labelize,
              x:    (idx * 78) - 195,
              y:    334
          } ,
          pitch: {
              txt:  'PITCH',
              x:    (idx * 78) - 196,
              y:    310
          },
          level: {
              txt:  'LEVEL',
              x:    (idx * 78) - 214,
              y:    202
          },
          pan: {
              txt:  'PAN',
              x:    (idx * 78) - 178,
              y:    202
          },
        }
      end

      frames = key_group_conf[:keys].map.with_index do |_, idx|
        {
            img: MiniMagick::Image.open("#{@gui_directory}/frame_channel.png"),
            x: 81 + (idx * 78)
        }
      end

      frames.drop(1).each do |e|
        wallpaper = wallpaper.composite(e[:img]) do |c|
          c.compose   "Over"
          c.geometry  "+#{e[:x]}+96"
        end
      end
      labels.each do |e|
        wallpaper = wallpaper.combine_options do |c|
          c.gravity   'south'
          c.font      FONT
          c.kerning   '1'
          c.pointsize '14'
          c.fill(TITLE_COLOR)
          c.draw      "text #{e[:title][:x]},#{e[:title][:y]} '#{e[:title][:txt]}'"
          c.pointsize '12'
          c.fill(TEXT_COLOR)
          c.draw      "text #{e[:pitch][:x]},#{e[:pitch][:y]} '#{e[:pitch][:txt]}'"
          c.draw      "text #{e[:level][:x]},#{e[:level][:y]} '#{e[:level][:txt]}'"
          c.draw      "text #{e[:pan][:x]},#{e[:pan][:y]} '#{e[:pan][:txt]}'"
        end
      end

      filename = "#{@gui_directory}/#{@tmp_prefix}wallpaper_mix_#{key_group_conf[:name]}.png"
      wallpaper.write(filename)
      @tmp_files << filename
      filename
    end

    def key_group(key_group_conf)
      {
        main: main_panel(key_group_conf),
        mix: mix_panel(key_group_conf)
      }
    end

    def instrument
      i = 0
      @key_groups = []
      @conf[:key_groups].each do |key_group_conf|
        i += 1
        @key_groups << key_group(key_group_conf)
        # break if i == 5
      end
      MiniMagick::Tool::Convert.new do |convert|
        convert.append.-
        @key_groups.each do |key_group_wallpapers|
          convert << key_group_wallpapers[:main]
          convert << key_group_wallpapers[:mix]
        end
        convert << "#{@gui_directory}/wallpaper_#{@project_name}.png"
      end
      FileUtils.rm(@tmp_files)
    end
  end
end