require "helper"

module QOI
  class ImageTest < Test
    IMGS = File.join(File.dirname(__FILE__), "images", "qoi_test_images")

    def test_rgba_on_rgba_image
      img = QOI::Image.from_file File.join(IMGS, "dice.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))

      # Test a few pixels
      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        expected = ChunkyPNG::Color.to_truecolor_alpha_bytes(png[x, y])
        assert_equal expected, img.rgba(x, y), "RGBA mismatch at (#{x}, #{y})"
      end
    end

    def test_rgb_on_rgba_image
      img = QOI::Image.from_file File.join(IMGS, "dice.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))

      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        expected = ChunkyPNG::Color.to_truecolor_bytes(png[x, y])
        assert_equal expected, img.rgb(x, y), "RGB mismatch at (#{x}, #{y})"
      end
    end

    def test_rgba_on_rgb_image
      img = QOI::Image.from_file File.join(IMGS, "kodim10.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "kodim10.png"))

      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        expected = ChunkyPNG::Color.to_truecolor_bytes(png[x, y]) + [255]
        assert_equal expected, img.rgba(x, y), "RGBA mismatch at (#{x}, #{y})"
      end
    end

    def test_rgb_on_rgb_image
      img = QOI::Image.from_file File.join(IMGS, "kodim10.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "kodim10.png"))

      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        expected = ChunkyPNG::Color.to_truecolor_bytes(png[x, y])
        assert_equal expected, img.rgb(x, y), "RGB mismatch at (#{x}, #{y})"
      end
    end

    def test_pixel_on_rgba_image
      img = QOI::Image.from_file File.join(IMGS, "dice.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "dice.png"))

      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        r, g, b, a = ChunkyPNG::Color.to_truecolor_alpha_bytes(png[x, y])
        expected = (r << 24) | (g << 16) | (b << 8) | a
        assert_equal expected, img.pixel(x, y), "Pixel mismatch at (#{x}, #{y})"
      end
    end

    def test_pixel_on_rgb_image
      img = QOI::Image.from_file File.join(IMGS, "kodim10.qoi")
      png = ChunkyPNG::Image.from_file(File.join(IMGS, "kodim10.png"))

      [[0, 0], [10, 10], [img.width - 1, img.height - 1]].each do |x, y|
        r, g, b = ChunkyPNG::Color.to_truecolor_bytes(png[x, y])
        expected = (r << 24) | (g << 16) | (b << 8) | 0xFF
        assert_equal expected, img.pixel(x, y), "Pixel mismatch at (#{x}, #{y})"
      end
    end

    def test_set_rgba_on_rgba_image
      img = QOI::Image.new(2, 2, 4, 0)
      img.set_rgba(0, 0, 255, 128, 64, 200)
      img.set_rgba(1, 0, 10, 20, 30, 40)
      img.set_rgba(0, 1, 100, 150, 200, 250)
      img.set_rgba(1, 1, 0, 0, 0, 255)

      assert_equal [255, 128, 64, 200], img.rgba(0, 0)
      assert_equal [10, 20, 30, 40], img.rgba(1, 0)
      assert_equal [100, 150, 200, 250], img.rgba(0, 1)
      assert_equal [0, 0, 0, 255], img.rgba(1, 1)
    end

    def test_set_rgb_on_rgba_image
      img = QOI::Image.new(2, 2, 4, 0)
      img.set_rgb(0, 0, 255, 128, 64)
      img.set_rgb(1, 1, 10, 20, 30)

      assert_equal [255, 128, 64], img.rgb(0, 0)
      assert_equal [10, 20, 30], img.rgb(1, 1)
      # Alpha should be set to 255 by set_rgb
      assert_equal [255, 128, 64, 255], img.rgba(0, 0)
    end

    def test_set_rgba_on_rgb_image
      img = QOI::Image.new(2, 2, 3, 0)
      img.set_rgba(0, 0, 255, 128, 64, 200)
      img.set_rgba(1, 1, 10, 20, 30, 40)

      # Alpha is ignored for RGB images
      assert_equal [255, 128, 64], img.rgb(0, 0)
      assert_equal [10, 20, 30], img.rgb(1, 1)
    end

    def test_set_rgb_on_rgb_image
      img = QOI::Image.new(2, 2, 3, 0)
      img.set_rgb(0, 0, 255, 128, 64)
      img.set_rgb(1, 0, 10, 20, 30)
      img.set_rgb(0, 1, 100, 150, 200)
      img.set_rgb(1, 1, 0, 0, 0)

      assert_equal [255, 128, 64], img.rgb(0, 0)
      assert_equal [10, 20, 30], img.rgb(1, 0)
      assert_equal [100, 150, 200], img.rgb(0, 1)
      assert_equal [0, 0, 0], img.rgb(1, 1)
    end
  end
end
