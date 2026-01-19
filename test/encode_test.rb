require "helper"

module QOI
  class EncodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    %w{ dice edgecase kodim10 kodim23
        qoi_logo testcard_rgba testcard wikipedia_008 }.each do |name|
      define_method("test_encoding_#{name}_roundtrip") do
        # Load the PNG and get pixel data
        png = ChunkyPNG::Image.from_file(File.join(IMGS, name + ".png"))

        # Use channels from reference QOI file
        reference = File.binread(File.join(IMGS, name + ".qoi"))
        channels = reference.getbyte(12)
        original_pixels = channels == 3 ? png.to_rgb_stream : png.to_rgba_stream

        # Create QOI buffer and encode it
        img = QOI::Image.new(png.width, png.height, channels, 0, original_pixels)
        encoded = img.encode

        # Verify roundtrip: decode our encoded data and compare pixels
        decoded = QOI::Image.from_buffer(encoded)
        assert_equal png.width, decoded.width, "Width mismatch"
        assert_equal png.height, decoded.height, "Height mismatch"
        assert_equal original_pixels, decoded.buffer, "Pixel data mismatch"
      end
    end
  end
end
