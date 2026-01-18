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
    def self.hash r, g, b, a
      (r * 3 + g * 5 + b * 7 + a * 11) % 64
    end

    def self.set_seen seen, index, pixel
      seen[index] = pixel.dup
    end

    def self.from_file name, reference
      File.open(name, "rb") do |file|
        raise Errors::FormatError unless "qoif".b == file.read(4)

        width, height, channels, colorspace = file.read(10).unpack("NNCC")

        buff = "\0".b * width * height * channels

        previous_pixel = [0, 0, 0, 255].pack("CCCC")
        seen_pixels = ["\0\0\0\0".b] * 64

        offset = 0

        while byte = file.getbyte
          break if offset >= width * height * channels

          if byte == 0xFE # RGB
            r = file.getbyte
            g = file.getbyte
            b = file.getbyte
            a = previous_pixel.getbyte(3)

            previous_pixel.setbyte(0, r)
            previous_pixel.setbyte(1, g)
            previous_pixel.setbyte(2, b)

            set_seen seen_pixels, hash(r, g, b, a), previous_pixel

            raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
            buff.bytesplice(offset, channels, previous_pixel)
            offset += channels
          elsif byte == 0xFF # RGBA
            r = file.getbyte
            g = file.getbyte
            b = file.getbyte
            a = file.getbyte

            previous_pixel.setbyte(0, r)
            previous_pixel.setbyte(1, g)
            previous_pixel.setbyte(2, b)
            previous_pixel.setbyte(3, a)

            set_seen seen_pixels, hash(r, g, b, a), previous_pixel

            raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
            buff.bytesplice(offset, channels, previous_pixel)
            offset += channels
          else
            if byte & 0xC0 == 0xC0 # QOI_OP_RUN
              ((byte & 0x3F) + 1).times do |i|
                raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
                buff.bytesplice(offset, channels, previous_pixel)
                offset += channels
              end
            elsif byte & 0xC0 == 0x80 # QOI_OP_LUMA
              dg = (byte & 0x3F) - 32

              byte = file.getbyte
              dr_dg = (byte >> 4) - 8
              db_dg = (byte & 0xF) - 8

              r = previous_pixel.getbyte(0) + dg + dr_dg
              g = previous_pixel.getbyte(1) + dg
              b = previous_pixel.getbyte(2) + dg + db_dg
              a = previous_pixel.getbyte(3)

              previous_pixel.setbyte(0, r)
              previous_pixel.setbyte(1, g)
              previous_pixel.setbyte(2, b)

              set_seen seen_pixels, hash(r, g, b, a), previous_pixel

              raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
              buff.bytesplice(offset, channels, previous_pixel)
              offset += channels
            elsif byte & 0xC0 == 0x40 # QOI_OP_DIFF
              dr = ((byte >> 4) & 0x03) - 2
              dg = ((byte >> 2) & 0x03) - 2
              db = (byte & 0x03) - 2

              r = previous_pixel.getbyte(0) + dr
              g = previous_pixel.getbyte(1) + dg
              b = previous_pixel.getbyte(2) + db
              a = previous_pixel.getbyte(3)

              previous_pixel.setbyte(0, r)
              previous_pixel.setbyte(1, g)
              previous_pixel.setbyte(2, b)

              set_seen seen_pixels, hash(r, g, b, a), previous_pixel

              raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
              buff.bytesplice(offset, channels, previous_pixel)
              offset += channels
            else # QOI_OP_INDEX
              index = byte
              previous_pixel = seen_pixels[index].dup
              raise unless reference.byteslice(offset, 4).bytes == previous_pixel.bytes
              buff.bytesplice(offset, channels, previous_pixel)
              offset += channels
            end
          end
        end

        new width, height, channels, colorspace, buff
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
