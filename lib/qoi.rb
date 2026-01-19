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
    def self.pixel_hash px # :nodoc:
      r = (px >> 24) & 0xFF
      g = (px >> 16) & 0xFF
      b = (px >> 8) & 0xFF
      a = px & 0xFF
      (r * 3 + g * 5 + b * 7 + a * 11) % 64
    end

    def self.decode ctx, reader # :nodoc:
      index = 0
      raise Errors::FormatError unless "qoif".b == reader.read(ctx, index, 4)
      index += 4

      width, height, channels, colorspace = reader.read(ctx, index, 10).unpack("NNCC")
      index += 10

      total_pixels = width * height
      buff = String.new(capacity: total_pixels * 4, encoding: Encoding::BINARY)

      # Pixel format: 0xRRGGBBAA (RGBA, high to low bits)
      # When packed as big-endian 32-bit, becomes R,G,B,A bytes
      px = 0x000000FF
      seen = Array.new(64, 0)
      seen[pixel_hash(px)] = px

      pixels_decoded = 0

      while true
        byte = reader.getbyte(ctx, index)
        index += 1
        break if pixels_decoded >= total_pixels

        if byte == 0xFE # QOI_OP_RGB
          px = (reader.read_uint24(ctx, index) << 8) | (px & 0xFF)
          index += 3
          seen[pixel_hash(px)] = px
          [px].pack("N", buffer: buff)

        elsif byte == 0xFF # QOI_OP_RGBA
          px = reader.read_uint32(ctx, index)
          index += 4
          seen[pixel_hash(px)] = px
          [px].pack("N", buffer: buff)

        elsif byte & 0xC0 == 0xC0 # QOI_OP_RUN
          run = byte & 0x3F
          (run + 1).times { [px].pack("N", buffer: buff) }
          pixels_decoded += run

        elsif byte & 0xC0 == 0x80 # QOI_OP_LUMA
          dg = (byte & 0x3F) - 32
          byte2 = reader.getbyte(ctx, index); index += 1
          dr_dg = (byte2 >> 4) - 8
          db_dg = (byte2 & 0x0F) - 8

          r = (((px >> 24) & 0xFF) + dg + dr_dg) & 0xFF
          g = (((px >> 16) & 0xFF) + dg) & 0xFF
          b = (((px >> 8) & 0xFF) + dg + db_dg) & 0xFF
          px = (r << 24) | (g << 16) | (b << 8) | (px & 0xFF)
          seen[pixel_hash(px)] = px
          [px].pack("N", buffer: buff)

        elsif byte & 0xC0 == 0x40 # QOI_OP_DIFF
          dr = ((byte >> 4) & 0x03) - 2
          dg = ((byte >> 2) & 0x03) - 2
          db = (byte & 0x03) - 2

          r = (((px >> 24) & 0xFF) + dr) & 0xFF
          g = (((px >> 16) & 0xFF) + dg) & 0xFF
          b = (((px >> 8) & 0xFF) + db) & 0xFF
          px = (r << 24) | (g << 16) | (b << 8) | (px & 0xFF)
          seen[pixel_hash(px)] = px
          [px].pack("N", buffer: buff)

        else # QOI_OP_INDEX
          px = seen[byte]
          [px].pack("N", buffer: buff)
        end

        pixels_decoded += 1
      end

      new width, height, 4, colorspace, buff
    end

    module FileHelper # :nodoc:
      def self.read_uint24 fh, _
        (fh.getbyte << 16) | (fh.getbyte << 8) | fh.getbyte
      end

      def self.read_uint32 fh, _
        (fh.getbyte << 24) | (fh.getbyte << 16) | (fh.getbyte << 8) | fh.getbyte
      end

      def self.read fh, _, size
        fh.read size
      end

      def self.getbyte fh, _
        fh.getbyte
      end
    end

    module BufferHelper # :nodoc:
      def self.read_uint24 buf, offset
        (buf.unpack1("C", offset: offset) << 16) |
          buf.unpack1("n", offset: offset + 1)
      end

      def self.read_uint32 buf, offset
        buf.unpack1("N", offset: offset)
      end

      def self.read buf, offset, size
        buf.byteslice(offset, size)
      end

      def self.getbyte buf, offset
        buf.getbyte offset
      end
    end

    def self.from_buffer buff
      decode buff, BufferHelper
    end

    def self.from_file name
      File.open(name, "rb") do |file|
        decode file, FileHelper
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
