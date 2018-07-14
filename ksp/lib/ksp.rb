require 'ksp/version'
require 'ksp/script'
require 'ksp/variable'
require 'ksp/integer'
require 'ksp/ui_control'
require 'ksp/ui_switch'
require 'ksp/image_size'
require 'ksp/ui_image'
require 'ksp/custom_button'
require 'ksp/ui_slider'
require 'ksp/ui_slider_v2'
require 'ksp/custom_diode'
require 'ksp/custom_knob'
require 'ksp/custom_fader'
require 'ksp/volume_fader'
require 'ksp/pan_fader'

module Ksp

  class Utility

    # When dragging a number of samples into a single key, Kontakt creates
    # velocity splits. Each key in this hash represents the number of samples
    # dragged in, and the splits are the (lowest) value in each velocity range
    def self.velocity_split_list
      {
          # '5' => [], # Missing
          '10' => [1, 13, 25, 38, 52, 63, 76, 89, 102, 114],
          # '32' => [], # Missing
          '64' => [1, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32,
                   34, 36, 38, 40, 42, 44, 46, 48, 50, 52, 54, 56, 58, 60, 62,
                   63, 65, 67, 69, 71, 73, 75, 77, 79, 81, 83, 85, 87, 89, 91,
                   93, 95, 97, 99, 101, 103, 105, 107, 109, 111, 113, 115, 117,
                   119, 121, 123, 125
          ],
          # '120' => [] # Missing
      }
    end

    def self.split_lists_declare
      velocity_split_list.map do |k, v|
        "declare %velocity_splits_#{k}[#{k}] := (#{v.join(', ')})"
      end
    end
  end


end
