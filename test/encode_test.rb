require "helper"

module QOI
  class EncodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")
    def test_encoding
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))
      p png.width
      p png.height
      p png.to_rgb_stream.bytesize

      buff = QOI::Buffer.new(png.width, png.height, 3, 0, png.to_rgb_stream)
      #p png.to_blob
    end
  end
end
