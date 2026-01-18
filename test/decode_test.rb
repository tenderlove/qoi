require "helper"

module QOI
  class DecodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    %w{ dice edgecase kodim10 kodim23
        qoi_logo testcard_rgba testcard wikipedia_008 }.each do |name|
      define_method("test_decode_#{name}") do
        png = ChunkyPNG::Image.from_file(File.join(IMGS, name + ".png"))
        buff = QOI::Buffer.from_file File.join(IMGS, name + ".qoi")

        assert_equal png.width, buff.width
        assert_equal png.height, buff.height
        assert_equal png.to_rgba_stream, buff.buffer
      end
    end
  end
end
