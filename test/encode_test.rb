require "helper"

module QOI
  class EncodeTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    %w{ dice edgecase kodim10 kodim23
        qoi_logo testcard_rgba testcard wikipedia_008 }.each do |name|
      define_method("test_encoding_#{name}_roundtrip") do
        # Load the PNG and get pixel data
        png = ChunkyPNG::Image.from_file(File.join(IMGS, name + ".png"))
        datastream = ChunkyPNG::Datastream.from_file(File.join(IMGS, name + ".png"))

        # Use channels based on PNG color type (4 or 6 have alpha channel)
        has_alpha_channel = [4, 6].include?(datastream.header_chunk.color)
        channels = has_alpha_channel ? 4 : 3
        original_pixels = has_alpha_channel ? png.to_rgba_stream : png.to_rgb_stream

        # Create QOI buffer and encode it
        img = QOI::Buffer.new(png.width, png.height, channels, 0, original_pixels)
        encoded = img.encode

        # Verify roundtrip: decode our encoded data and compare pixels
        # Decoder always outputs RGBA, so compare with RGBA stream
        decoded = QOI::Buffer.from_buffer(encoded)
        assert_equal png.width, decoded.width, "Width mismatch"
        assert_equal png.height, decoded.height, "Height mismatch"
        assert_equal png.to_rgba_stream, decoded.buffer, "Pixel data mismatch"
      end
    end
  end
end
