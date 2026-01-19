# QOI

A Ruby implementation of the [QOI (Quite OK Image)](https://qoiformat.org) format.

## Installation

Just add it to your Gemfile!

```ruby
gem 'qoi'
```

## Usage

### Decoding

```ruby
require 'qoi'

# From file
image = QOI::Image.from_file("photo.qoi")

# From binary string
image = QOI::Image.from_buffer(qoi_data)

# Access image properties
image.width      # => 800
image.height     # => 600
image.channels   # => 4 (RGBA) or 3 (RGB)
image.colorspace # => 0 (sRGB) or 1 (linear)
```

### Encoding

```ruby
# Create a new image
image = QOI::Image.new(100, 100, QOI::Channels::RGBA, QOI::Colorspace::SRGB)

# Set pixels
image.set_rgba(0, 0, 255, 0, 0, 255)  # red pixel at (0,0)
image.set_rgb(1, 0, 0, 255, 0)        # green pixel at (1,0)

# Encode to QOI
qoi_data = image.encode
File.binwrite("output.qoi", qoi_data)
```

### Converting from PNG with ChunkyPNG

```ruby
require 'qoi'
require 'chunky_png'

png = ChunkyPNG::Image.from_file("input.png")
image = QOI::Image.new(png.width, png.height, QOI::Channels::RGBA, QOI::Colorspace::SRGB, png.to_rgba_stream)
File.binwrite("output.qoi", image.encode)
```

### Reading Pixels

```ruby
image.rgba(x, y)  # => [r, g, b, a]
image.rgb(x, y)   # => [r, g, b]
image.pixel(x, y) # => 0xRRGGBBAA (packed integer)
image.buffer      # => raw pixel data as binary string
```

## License

MIT
