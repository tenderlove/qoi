require "helper"

module QOI
  class EncodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    def test_encoding
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))
      p png.width
      p png.height
      raw = png.to_rgba_stream
      i = 0
      loop do
        break if raw.getbyte(i) > 0
        i += 1
      end
      p R: raw.getbyte(71412)
      p G: raw.getbyte(71413)
      p B: raw.getbyte(71414)
      p A: raw.getbyte(71415)

      buff = QOI::Buffer.new(png.width, png.height, Channels::RGBA, 0, png.to_rgba_stream)
      #p png.to_blob
    end
  end
end
