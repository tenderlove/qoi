# frozen_string_literal: true

module QOI
  autoload :VERSION, "qoi/version"

  module Errors
    class Error < StandardError; end
    class FormatError < Error; end
  end

  module Channels
    RGB = 3
    RGBA = 4
  end

  module Colorspace
    SRGB = 0
    ALL = 1
  end

  class Buffer
    # Pixel format: 0xAABBGGRR (ABGR, high to low bits)
    # When packed as little-endian 32-bit, becomes R,G,B,A bytes

    def self.pixel_hash px
      r = px & 0xFF
      g = (px >> 8) & 0xFF
      b = (px >> 16) & 0xFF
      a = (px >> 24) & 0xFF
      (r * 3 + g * 5 + b * 7 + a * 11) % 64
    end

    def self.decode ctx, reader
      index = 0
      raise Errors::FormatError unless "qoif".b == reader.read(ctx, index, 4)
      index += 4

      width, height, channels, colorspace = reader.read(10).unpack("NNCC")
      index += 10

      total_pixels = width * height
      buff = String.new(capacity: total_pixels * 4, encoding: Encoding::BINARY)

      #    AABBGGRR
      px = 0xFF000000
      seen = Array.new(64, 0)
      seen[pixel_hash(px)] = px

      pixels_decoded = 0

      while byte = file.getbyte
        break if pixels_decoded >= total_pixels

        if byte == 0xFE # QOI_OP_RGB
          r = file.getbyte
          g = file.getbyte
          b = file.getbyte
          px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
          seen[pixel_hash(px)] = px
          [px].pack("V", buffer: buff)

        elsif byte == 0xFF # QOI_OP_RGBA
          r = file.getbyte
          g = file.getbyte
          b = file.getbyte
          a = file.getbyte
          px = (a << 24) | (b << 16) | (g << 8) | r
          seen[pixel_hash(px)] = px
          [px].pack("V", buffer: buff)

        elsif byte & 0xC0 == 0xC0 # QOI_OP_RUN
          run = byte & 0x3F
          (run + 1).times { [px].pack("V", buffer: buff) }
          pixels_decoded += run

        elsif byte & 0xC0 == 0x80 # QOI_OP_LUMA
          dg = (byte & 0x3F) - 32
          byte2 = file.getbyte
          dr_dg = (byte2 >> 4) - 8
          db_dg = (byte2 & 0x0F) - 8

          r = ((px & 0xFF) + dg + dr_dg) & 0xFF
          g = (((px >> 8) & 0xFF) + dg) & 0xFF
          b = (((px >> 16) & 0xFF) + dg + db_dg) & 0xFF
          px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
          seen[pixel_hash(px)] = px
          [px].pack("V", buffer: buff)

        elsif byte & 0xC0 == 0x40 # QOI_OP_DIFF
          dr = ((byte >> 4) & 0x03) - 2
          dg = ((byte >> 2) & 0x03) - 2
          db = (byte & 0x03) - 2

          r = ((px & 0xFF) + dr) & 0xFF
          g = (((px >> 8) & 0xFF) + dg) & 0xFF
          b = (((px >> 16) & 0xFF) + db) & 0xFF
          px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
          seen[pixel_hash(px)] = px
          [px].pack("V", buffer: buff)

        else # QOI_OP_INDEX
          px = seen[byte]
          [px].pack("V", buffer: buff)
        end

        pixels_decoded += 1
        index += 1
      end

      new width, height, 4, colorspace, buff
    end

    def self.from_file name
      File.open(name, "rb") do |file|
        index = 0
        raise Errors::FormatError unless "qoif".b == file.read(4)
        index += 4

        width, height, channels, colorspace = file.read(10).unpack("NNCC")
        index += 10

        total_pixels = width * height
        buff = String.new(capacity: total_pixels * 4, encoding: Encoding::BINARY)

        #    AABBGGRR
        px = 0xFF000000
        seen = Array.new(64, 0)
        seen[pixel_hash(px)] = px

        pixels_decoded = 0

        while byte = file.getbyte
          break if pixels_decoded >= total_pixels

          if byte == 0xFE # QOI_OP_RGB
            r = file.getbyte
            g = file.getbyte
            b = file.getbyte
            px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
            seen[pixel_hash(px)] = px
            [px].pack("V", buffer: buff)

          elsif byte == 0xFF # QOI_OP_RGBA
            r = file.getbyte
            g = file.getbyte
            b = file.getbyte
            a = file.getbyte
            px = (a << 24) | (b << 16) | (g << 8) | r
            seen[pixel_hash(px)] = px
            [px].pack("V", buffer: buff)

          elsif byte & 0xC0 == 0xC0 # QOI_OP_RUN
            run = byte & 0x3F
            (run + 1).times { [px].pack("V", buffer: buff) }
            pixels_decoded += run

          elsif byte & 0xC0 == 0x80 # QOI_OP_LUMA
            dg = (byte & 0x3F) - 32
            byte2 = file.getbyte
            dr_dg = (byte2 >> 4) - 8
            db_dg = (byte2 & 0x0F) - 8

            r = ((px & 0xFF) + dg + dr_dg) & 0xFF
            g = (((px >> 8) & 0xFF) + dg) & 0xFF
            b = (((px >> 16) & 0xFF) + dg + db_dg) & 0xFF
            px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
            seen[pixel_hash(px)] = px
            [px].pack("V", buffer: buff)

          elsif byte & 0xC0 == 0x40 # QOI_OP_DIFF
            dr = ((byte >> 4) & 0x03) - 2
            dg = ((byte >> 2) & 0x03) - 2
            db = (byte & 0x03) - 2

            r = ((px & 0xFF) + dr) & 0xFF
            g = (((px >> 8) & 0xFF) + dg) & 0xFF
            b = (((px >> 16) & 0xFF) + db) & 0xFF
            px = (px & 0xFF000000) | (b << 16) | (g << 8) | r
            seen[pixel_hash(px)] = px
            [px].pack("V", buffer: buff)

          else # QOI_OP_INDEX
            px = seen[byte]
            [px].pack("V", buffer: buff)
          end

          pixels_decoded += 1
          index += 1
        end

        new width, height, 4, colorspace, buff
      end
    end

    attr_reader :width, :height, :channels, :colorspace, :buffer

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
