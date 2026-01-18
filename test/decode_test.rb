require "helper"

module QOI
  class DecodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    def test_encoding_dice_png
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))
      buff = QOI::Buffer.from_file File.join(IMGS, "dice.qoi"), png.to_rgba_stream

      assert_equal png.width, buff.width
      assert_equal png.height, buff.height
      assert_equal png.to_rgba_stream, buff.buffer
    end

    def test_encoding_edgecase
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "edgecase.png"))
      buff = QOI::Buffer.from_file File.join(IMGS, "edgecase.qoi"), png.to_rgba_stream

      assert_equal png.width, buff.width
      assert_equal png.height, buff.height
      assert_equal png.to_rgba_stream, buff.buffer
    end
  end
end
