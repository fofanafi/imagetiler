# imagetiler -- A simple tool to tile images.

imagetiler is a simple command-line and ruby image tiler with support for multiple zoom levels and different image formats.


## How to use

### From the command line

`ruby tile_image.rb -o OUTPUT_DIR -z ZOOM_LEVELS IMAGE_FILE`  

For example

`ruby tile_image.rb -o ./tiles -z 2..4 ./input_files/map.jpg`


### From ruby

Install ImageMagick.

Install the gem:  
`gem install rmagick`  
`gem install imagetiler`

Use it in your code:  
	require 'rubygems' # if you installed imagetiler as a gem
	require 'imagetiler' 
	t = Tiler.new   
	t.make_tiles(image_source, opts)

`image_source` can be either a filename or an RMagick Image.

You can set options two ways:  
`t.zoom_levels = 2..4`  
or  
`t.get_tiles(image, :zoom_levels => 2..4)`

If you set an option in get_tiles, that will be the new default for that instance of Tiler.


## Options

`zoom_levels` : Zoom level 0 shows the entire image as one 256x256 tile. Subsequent zoom levels double both the horizontal and vertical sides. Default is 0..4  
`output_dir` : Defaults to the current directory. Don't include the ending '/'  
`bg_color` : The background fill color, transparent by default.  
`autocreate_dirs` : Whether or not to create the directory if it exists. Default true  
`format` : The format for the output, defaults to 'png'. Can be png, jpg, gif, or anything that ImageMagick supports. 
`prefix` : Prefix for the output files. Defaults to 'tile'


## Methods

`make_tiles(image_source, opts)`  

`calc_native_res_zoom` : Calculates the zoom level closest to native resolution. Returns a float for the zoom -- so, use zoom.round if you want the closest zoom level, for example.


## Output
Tiles in the output folder with format  
`#{output_dir}/#{prefix}_#{zoom_level}_#{tile_col}_#{tile_row}.#{image_format}`


## Other things
* Requires rmagick and ImageMagick.


## Credits
This tiler is modified Guilhem's tile_image.rb tool, which is part of the ym4r project. The Tiler itself has been re-written, and TileParam is no longer used.  
Thanks to Guilhem for the command-line portions and the sample ruby and rmagick code!


## License
imagetiler uses the MIT License.
