module Beaotic
  class Key
    attr_reader :name
    attr_accessor :midi_note

    def initialize(key_conf = {})
      # Example conf:
      # - name: sd_8
      #   midi_note: 49
      #   k_groups:
      #     osc1: [48]
      #     osc2: !ruby/range 49..53

      @conf = key_conf
      @midi_note = key_conf[:midi_note]
    end

    def initialize_old(key_group, idx, conf)
      @key_group = key_group
      @idx = idx
      @conf = conf
      @midi_note = conf[:midi_note]
      @name = conf[:name]
      @callback = []
      @off_callback = []
    end

    def set_k_groups
      statements = []
      @conf[:k_groups].keys.each do |osc|
        var = Ksp::Variable.new(
            type: 'integer_array',
            name: "key_#{@conf[:midi_note]}_k_groups_#{osc}",
            arr_length: @conf[:k_groups][osc].count,
            default_value: @conf[:k_groups][osc]
        )
        statements += var.statements
      end
      statements
    end

    # Round Robin and our Color-concept become quite intertwined, as also mentioned in comment above.
    # TODO: Make prettier!

    def set_off_callback
      @off_callback << "if ($EVENT_NOTE = #{midi_note})"
      @off_callback << "  #{@key_group.diode.name} := 0" if @key_group.diode
      @off_callback << 'end if'
    end
  end
end