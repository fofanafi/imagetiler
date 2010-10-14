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

class Tiler

	TILE_SIZE = 256

	attr_accessor(:output_dir, :zoom_levels, :bg_color, 
								:format, :autocreate_dirs, :prefix)

	def initialize()
		@zoom_levels = 0..4
		@bg_color = Magick::Pixel.new(255,255,255,Magick::TransparentOpacity)
		@format = "png"
		@autocreate_dirs = true
		@output_dir = "."
		@prefix = "tile"
	end
	
	# image_source can either be an RMagick Image or a string specifying the filename
	def make_tiles(image_source, opts={})

		# initializing and setting options and stuff
		image = get_image(image_source)
		opts.each_pair do |key,value|
       instance_variable_set "@#{key}", value
    end

		if @autocreate_dirs
			create_dir(output_dir)
		end

		# pad image with background color so image is square
		image_sq = pad_image(image)
		image_length = image_sq.columns

		# the actual tiling part!
		zoom_levels.each do |zoom|
			# get the number of tiles in each column and row
			factor = 2 ** zoom

			# get length of tiles for current zoom
			tile_length = image_length / factor

			0.upto(factor-1) do |col|
				0.upto(factor-1) do |row|

					# cut tile
					# Image.crop(x,y,width,height,toss offset information)
					tile = image_sq.crop(col*tile_length, row*tile_length,
															 tile_length, tile_length, true)
					tile.resize!(TILE_SIZE,TILE_SIZE)

					# output tile
					filename = File.join(@output_dir, "#{prefix}_#{zoom}_#{col}_#{row}.#{@format}")
					tile.write(filename)
				end
			end
		end
	end

	# Calculates the zoom level closest to native resolution.
	# Returns a float for the zoom -- so, use zoom.ceil if you
	# want the higher zoom, for example
	def calc_native_res_zoom(image_source)
		image = get_image(image_source)
		side_length = calc_side_length(image)
		zoom = log2(side_length)-log2(TILE_SIZE)
		zoom = 0 if zoom < 0
		zoom
	end

	# pad image to the lower right with bg_color so that the 
	# image is square and that the max number of pixels
	# is evenly divisible by the max number of tiles per side
	def pad_image(image)
		dim = calc_side_length(image)
		
		image.background_color = @bg_color
		image.extent(dim, dim)
	end

	def get_image(image_source)
		case image_source
		when Magick::Image
			image = image_source
		else
			image = Magick::ImageList::new(image_source)
		end
		return image
	end

	def calc_side_length(image)
		long_side = [image.columns, image.rows].max
		max_zoom = @zoom_levels.max
		ceil = (long_side.to_f()/2**max_zoom).ceil
		side_length = ceil*2**max_zoom
	end

	# if dir does not exist, create it
	def create_dir(dir)
		if !FileTest::directory?(dir)
			Dir::mkdir(dir)
		end
	end

	def log2(x)
		Math.log(x)/Math.log(2)
	end

end

# Runs this as a script
def main

	OptionParser.accept(Range, /(\d+)\.\.(\d+)/) do |range,start,finish|
		Range.new(start.to_i,finish.to_i)
	end

	OptionParser.accept(Magick::Pixel,/(\d+),(\d+),(\d+),(\d+)/) do |pixel, r,g,b,a|
		Magick::Pixel.new(r.to_f,g.to_f,b.to_f,a.to_f)
	end

	options = {}

	opts = OptionParser.new do |opts|
		opts.banner = "Image Tiler for Google Maps\nUsage: tile_image.rb [options] IMAGE_FILE \nExample: tile_image.rb -o ./tiles -z 11..12 -p 602,768,11,78,112,1.91827348 ./input_files/map.jpg"
		opts.separator "" 
		opts.on("-o","--output OUTPUT_DIR","Directory where the tiles will be created") do |dir| 
			options[:output_dir] = dir
		end
		opts.on("-f","--format FORMAT","Image format in which to get the file (gif, jpeg, png...). Is jpg by default") do |format|
			options[:format] = format
		end
		opts.on("-z","--zoom_levels ZOOM_RANGE",Range,"Range of zoom values at which the tiles must be generated. Is 0..4 by default") do |range|
			options[:zoom_levels] = range
		end
		opts.on("-b","--background COLOR",Magick::Pixel,"Background color components. Is fully transparent par default") do |bg|
			options[:bg_color] = bg
		end
		opts.on("-p","--prefix PREFIX","Prefix to file output. Is 'tile' by default") do |prefix|
			options[:prefix] = prefix
		end
		opts.on_tail("-h", "--help", "Show this message") do
			puts opts
			exit
		end
	end

	opts.parse!(ARGV)

	#test the presence of all the options and exit with an error message
	error = []
	error << "No output directory defined (-o,--output)" if options[:output_dir].nil?
	error << "No input files defined" if ARGV.empty?

	unless error.empty?
		puts error * "\n" + "\n\n"
		puts opts
		exit
	end

	t = Tiler.new
	t.make_tiles(ARGV[0], options) # ignore all input files but first

end

# Executes the main method if this file is being run as a script.
if $0 == __FILE__
	main
end


