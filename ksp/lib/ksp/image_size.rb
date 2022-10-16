require 'stringio'
require 'tempfile'

module Ksp
  # boiled down version of https://github.com/toy/image_size/blob/master/lib/image_size.rb
  class ImageSize
    class FormatError < StandardError; end

    class Size < Array
      # join using 'x'
      def to_s
        join('x')
      end
    end

    class ImageReader # :nodoc:
      attr_reader :data
      def initialize(data_or_io)
        @io = case data_or_io
                when IO, StringIO, Tempfile
                  data_or_io.dup.tap(&:rewind)
                when String
                  StringIO.new(data_or_io)
                else
                  raise ArgumentError.new("expected instance of IO, StringIO, Tempfile or String, got #{data_or_io.class}")
              end
        @read = 0
        @data = ''
      end

      def close
        @io.rewind
        @io.close if IO === @io
      end

      CHUNK = 1024
      def [](offset, length)
        while offset + length > @read
          @read += CHUNK
          if data = @io.read(CHUNK)
            if data.respond_to?(:encoding)
              data.force_encoding(@data.encoding)
            end
            @data << data
          end
        end
        @data[offset, length]
      end
    end

    # Given path to image finds its format, width and height
    def self.path(path)
      open(path, 'rb'){ |f| new(f) }
    end

    # Given image as IO, StringIO, Tempfile or String finds its format and dimensions
    def initialize(data)
      ir = ImageReader.new(data)
      @format = :png
      @width, @height = self.send("size_of_#{@format}", ir)
      ir.close
    end

    # Image format
    attr_reader :format

    # Image width
    attr_reader :width
    alias :w :width

    # Image height
    attr_reader :height
    alias :h :height

    # get image width and height as an array which to_s method returns "#{width}x#{height}"
    def size
      Size.new([width, height]) if format
    end

    private

    def size_of_png(ir)
      unless ir[12, 4] == 'IHDR'
        raise FormatError, 'IHDR not in place for PNG'
      end
      ir[16, 8].unpack('NN')
    end
    alias_method :size_of_apng, :size_of_png
  end
end