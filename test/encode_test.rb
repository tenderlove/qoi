require "helper"

module QOI
  class EncodeTest < Test
    def test_encoding
      png = ChunkyPNG::Image.from_file("/Users/aaron/Downloads/qoi_test_images/dice.png")
      p png.width
      p png.height
      p png.to_rgb_stream.bytesize

      buff = QOI::Buffer.new(png.width, png.height, 3, 0, png.to_rgb_stream)
      #p png.to_blob
    end
  end
end
