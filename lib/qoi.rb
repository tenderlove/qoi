# frozen_string_literal: true

module QOI
  autoload :VERSION, "qoi/version"

  class Buffer
    def initialize width, height, channels, colorspace, buffer = empty_buffer(width, height, channels)
      @width = width
      @height = height
      @channels = channels
      @colorspace = colorspace
      @buffer = buffer
    end

    private

    def empty_buffer width, height, channels
      "\0".b * (width * height * channels)
    end
  end
end
