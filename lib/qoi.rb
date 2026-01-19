# frozen_string_literal: true
# encoding: ascii-8bit

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
      raise Errors::FormatError unless "qoif" == reader.read(ctx, index, 4)
      index += 4

      width, height, channels, colorspace = reader.read(ctx, index, 10).unpack("NNCC")
      index += 10

      total_pixels = width * height
      buff = String.new(capacity: total_pixels * channels, encoding: Encoding::BINARY)
      writer = channels == 3 ? RGBWriter : RGBAWriter

      # Pixel format: 0xRRGGBBAA (RGBA, high to low bits)
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
          writer.write(px, buff)

        elsif byte == 0xFF # QOI_OP_RGBA
          px = reader.read_uint32(ctx, index)
          index += 4
          seen[pixel_hash(px)] = px
          writer.write(px, buff)

        elsif byte & 0xC0 == 0xC0 # QOI_OP_RUN
          run = byte & 0x3F
          (run + 1).times { writer.write(px, buff) }
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
          writer.write(px, buff)

        elsif byte & 0xC0 == 0x40 # QOI_OP_DIFF
          dr = ((byte >> 4) & 0x03) - 2
          dg = ((byte >> 2) & 0x03) - 2
          db = (byte & 0x03) - 2

          r = (((px >> 24) & 0xFF) + dr) & 0xFF
          g = (((px >> 16) & 0xFF) + dg) & 0xFF
          b = (((px >> 8) & 0xFF) + db) & 0xFF
          px = (r << 24) | (g << 16) | (b << 8) | (px & 0xFF)
          seen[pixel_hash(px)] = px
          writer.write(px, buff)

        else # QOI_OP_INDEX
          px = seen[byte]
          writer.write(px, buff)
        end

        pixels_decoded += 1
      end

      new width, height, channels, colorspace, buff
    end

    module RGBReader # :nodoc:
      def self.read buff, pos
        (buff.getbyte(pos) << 24) | (buff.getbyte(pos + 1) << 16) | (buff.getbyte(pos + 2) << 8) | 0xFF
      end
    end

    module RGBAReader # :nodoc:
      def self.read buff, pos
        buff.unpack1("N", offset: pos)
      end
    end

    module RGBWriter # :nodoc:
      def self.write px, buff
        buff << ((px >> 24) & 0xFF) << ((px >> 16) & 0xFF) << ((px >> 8) & 0xFF)
      end
    end

    module RGBAWriter # :nodoc:
      def self.write px, buff
        [px].pack("N", buffer: buff)
      end
    end

    def self.encode width, height, channels, colorspace, buffer
      out = String.new(capacity: 14 + width * height * 5 + 8, encoding: Encoding::BINARY)

      # Header
      out << "qoif"
      [width, height, channels, colorspace].pack("NNCC", buffer: out)

      # Pixel format: 0xRRGGBBAA (RGBA, high to low bits)
      previous_pixel = 0x000000FF
      pixel_lut = Array.new(64, 0)
      reader = channels == 3 ? RGBReader : RGBAReader

      run = 0
      total_pixels = width * height * channels
      last_pixel = total_pixels - channels
      pos = 0

      while true
        break unless pos < total_pixels

        pixel = reader.read(buffer, pos)

        if pixel == previous_pixel
          run += 1
          if run == 62 || pos == last_pixel
            out << (0xC0 | (run - 1))
            run = 0
          end
        else
          if run > 0
            out << (0xC0 | (run - 1))
            run = 0
          end

          index = pixel_hash(pixel)
          if pixel_lut[index] == pixel
            out << index
          else
            pixel_lut[index] = pixel

            # if the alpha is the same
            if (pixel & 0xFF) == (previous_pixel & 0xFF)
              vr = (pixel >> 24) - (previous_pixel >> 24)
              vg = ((pixel >> 16) & 0xFF) - ((previous_pixel >> 16) & 0xFF)
              vb = ((pixel >> 8) & 0xFF) - ((previous_pixel >> 8) & 0xFF)

              # Handle wraparound (e.g., 255->0 is +1, not -255)
              vr = vr - 256 if vr > 127
              vr = vr + 256 if vr < -127
              vg = vg - 256 if vg > 127
              vg = vg + 256 if vg < -127
              vb = vb - 256 if vb > 127
              vb = vb + 256 if vb < -127

              vg_r = vr - vg
              vg_b = vb - vg

              if vr > -3 && vr < 2 && vg > -3 && vg < 2 && vb > -3 && vb < 2
                # QOI_OP_DIFF
                out << (0x40 | ((vr + 2) << 4) | ((vg + 2) << 2) | (vb + 2))
              elsif vg_r > -9 && vg_r < 8 && vg > -33 && vg < 32 && vg_b > -9 && vg_b < 8
                # QOI_OP_LUMA
                [0x80 | (vg + 32), ((vg_r + 8) << 4) | (vg_b + 8)].pack("CC", buffer: out)
              else
                # QOI_OP_RGB
                [0xFE_00_00_00 | (pixel >> 8)].pack("N", buffer: out)
              end
            else
              # QOI_OP_RGBA
              [0xFF, pixel].pack("CN", buffer: out)
            end
          end
        end

        previous_pixel = pixel
        pos += channels
      end

      # Flush final run
      if run > 0
        out << (0xC0 | (run - 1)).chr
      end

      # End marker
      out << "\x00\x00\x00\x00\x00\x00\x00\x01"

      out
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

    def encode
      Buffer.encode(width, height, channels, colorspace, buffer)
    end

    private

    def empty_buffer width, height, channels
      "\0".b * (width * height * channels)
    end
  end
end
