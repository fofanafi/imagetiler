#  Copyright (c) 2010 Anna <tanna22@gmail.com>
#  Copyright (c) 2006 Guilhem Vellut <guilhem.vellut+ym4r@gmail.com>
#  
#  Permission is hereby granted, free of charge, to any person obtaining a copy of this software
#  and associated documentation files (the "Software"), to deal in the Software without
#  restriction, including without limitation the rights to use, copy, modify, merge, publish,
#  distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
#  Software is furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be included in all copies or
#  substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
#  BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
#  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
#  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'RMagick'
require 'optparse'
require 'ostruct'

module Tiler
  #Structure that contains configuration data for the Image tiler
  class TileParam < Struct.new(:ul_corner,:zoom,:padding,:scale)
  end
  
  class Point < Struct.new(:x,:y)
    def -(point)
      Point.new(x - point.x , y - point.y)
    end
    def +(point)
      Point.new(x + point.x , y + point.y)
    end
    def *(scale)
      Point.new(scale * x,scale * y)
    end
    def to_s
      "Point #{x} #{y}"
    end
  end
  
  TILE_SIZE = 256
          
  def get_tiles(output_dir, input_files, zooms, bg_color = Magick::Pixel.new(255,255,255,0), format = "jpg")
    
	# ignore all files but the first
	input_file = input_files[0]

	image = Magick::ImageList::new(input_file)

	# pad image with background color so everything divides evenly
	image = pad_image(image, zooms.max, bg_color)
    image_length = image.columns

    zooms.each do |zoom|
	  # get the number of tiles in each column and row
      factor = 2 ** zoom

	  # get length of tiles for current zoom
      tile_length = image_length / factor

	  0.upto(factor-1) do |col|
		  0.upto(factor-1) do |row|
			  # Image.crop(x,y,width,height,toss offset information)
			  tile = image.crop(col*tile_length, row*tile_length,
							   tile_length, tile_length, true)
			  tile.resize!(TILE_SIZE,TILE_SIZE)
			  tile.write("#{output_dir}/tile_#{zoom}_#{col}_#{row}.#{format}")
		  end
	  end
	end
  end
  
	def pad_image(image, max_zoom, bg_color)
		long_side = [image.columns, image.rows].max
		ceil = (long_side/2**max_zoom).ceil
		dimension_image = ceil*2**max_zoom
		
		image_sq = Magick::Image.new(dimension_image, dimension_image) do
			self.background_color = bg_color
		end
		
		image_sq.import_pixels(0,0,image.columns,image.rows,"RGBA",image.export_pixels(0,0,image.columns,image.rows,"RGBA"))
	end
end

# Runs this as a script
def main
  include Tiler
  
  OptionParser.accept(Range, /(\d+)\.\.(\d+)/) do |range,start,finish|
    Range.new(start.to_i,finish.to_i)
  end
  
  OptionParser.accept(TileParam, /(\d+),(\d+),(\d+),(\d+),(\d+),([\d.]+)/) do |setting,l_corner, u_corner, zoom, padding_x, padding_y, scale|
    TileParam.new(Point.new(l_corner.to_i,u_corner.to_i),zoom.to_i,Point.new(padding_x.to_i,padding_y.to_i),scale.to_f)
  end
  
  OptionParser.accept(Magick::Pixel,/(\d+),(\d+),(\d+),(\d+)/) do |pixel, r,g,b,a|
    Magick::Pixel.new(r.to_f,g.to_f,b.to_f,a.to_f)
  end
  
  options = OpenStruct.new
  #set some defaults
  options.format = "jpg"
  options.zoom_range = 0..4
  options.bg_color = Magick::Pixel.new(255,255,255,255)
  options.tile_param = TileParam.new(Point.new(0,0),0,Point.new(0,0),1.0)
  
  opts = OptionParser.new do |opts|
    opts.banner = "Image Tiler for Google Maps\nUsage: tile_image.rb [options] IMAGE_FILE \nExample: tile_image.rb -o ./tiles -z 11..12 -p 602,768,11,78,112,1.91827348 ./input_files/map.jpg"
    opts.separator "" 
    opts.on("-o","--output OUTPUT_DIR","Directory where the tiles will be created") do |dir| 
      options.output_dir = dir
    end
    opts.on("-f","--format FORMAT","Image format in which to get the file (gif, jpeg, png...). Is jpg by default") do |format|
      options.format = format
    end
    opts.on("-z","--zooms ZOOM_RANGE",Range,"Range of zoom values at which the tiles must be generated. Is 0..4 by default") do |range|
      options.zoom_range = range
    end
    opts.on("-p","--tile-param PARAM",TileParam,"Corner coordinates, furthest zoom level, padding in X and Y, scale") do |tp|
      options.tile_param = tp
    end
    opts.on("-b","--background COLOR",Magick::Pixel,"Background color components. Is fully transparent par default") do |bg|
      options.bg_color = bg
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  
  opts.parse!(ARGV)
  
  #test the presence of all the options and exit with an error message
  error = []
  error << "No output directory defined (-o,--output)" if options.output_dir.nil?
  error << "No input files defined" if ARGV.empty?
  
  unless error.empty?
    puts error * "\n" + "\n\n"
    puts opts
    exit
  end
  
  get_tiles(options.output_dir,ARGV,options.zoom_range,options.bg_color,options.format)
  
end

# Executes the main method if this file is being run as a script.
if $0 == __FILE__
  main
end

                      
