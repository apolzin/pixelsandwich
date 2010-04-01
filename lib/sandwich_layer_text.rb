class SandwichLayerText < SandwichLayer

	include GD2

	FACTOR = 1.0 / 255


	DEFAULTS = {
		:cache_dir				=> '/tmp/pixelsandwich/cache/textlayers/',
		:font_dir					=> '../fonts/',
		:fontname					=> 'Vera.ttf',
		:float_width			=> 0,
		:cut							=> 0,
		:gradient					=> false,
		:words						=> 'undefined',
		:size							=> 10,
		:color						=> '000000',
		:alignment				=> 'left'
	}

	attr_accessor :cache_dir, :font_dir, :fontname, :float_width, :cut, :gradient, :words,
								:size, :color, :gradient_from, :gradient_to, :file_name, :gd_image,
								:box_height, :box_width, :gd_font, :words_array, :alignment, :image_width, :image_height

	def initialize(options={})
		options = DEFAULTS.merge options

		options.each do |key, value|
			self.send(key.to_s + "=", value)
		end
		create_directories
		@foreground_color = SandwichLayerText.hex_to_f(@color)
		@file_name = @cache_dir + Digest::MD5.hexdigest(options.to_s) << '.png'
		super
	end

	def self.hex_to_f(hex_encoded)
		hex_encoded.scan(/../).map { |c| FACTOR * c.hex }
	end

	BLACK = SandwichLayerText.hex_to_f("000000")

	def render
		if File.exists? @file_name
			return @file_name
		else
			@gd_font = gd_font
			prepare_string
			create_image
			draw_text
		end
	end

	private

	def create_directories
		FileUtils.mkdir_p @cache_dir unless File.exists? @cache_dir
		FileUtils.mkdir_p @font_dir unless File.exists? @font_dir
	end

	def gd_font
		if File.exists?("#{@font_dir}#{@fontname}")
			font_path = "#{@font_dir}#{@fontname}"
			begin
				font = Font::TrueType[font_path, @size * 5]
			rescue Exception => e
				raise e.class, "Could not read font #{@fontname} (#{font_path})."
			end
			font
		else
			nil
		end
	end

	def draw_text
		count = 0
		magick_slices = []
		@words_array.each do |line|
			slice = create_slice
			slice.save_alpha = true
			slice.alpha_blending = true
			slice.draw do |dd|
				bg_alpha = 0.0
				transparent = @gd_image.palette.resolve Color[BLACK[0], BLACK[1], BLACK[2], 1.0]
				dd.color = transparent
				dd.fill
				hor = @box_height / @words_array.nitems - ((@size * 1.4 - @size) * 5)
				case @alignment
					when 'left'
						dd.move_to 0, hor
					when 'center'
						dd.move_to(((0 + @box_width - string_width(line)) / 2), hor)
					when 'right'
						dd.move_to 0 + @box_width - string_width(line), hor
				end
				foreground_color = @gd_image.palette.resolve Color[@foreground_color[0], @foreground_color[1], @foreground_color[2]]
				dd.color = foreground_color
				dd.font = @gd_font
				dd.text line
				slice.transparent = transparent
				slice.export @file_name.gsub(/\.png/,"_normal_#{count}.png")
				magick_slice = Magick::ImageList.new(@file_name.gsub(/\.png/,"_normal_#{count}.png")){
					self.depth = 32 }.pop
				magick_slice.resize! 0.20
				magick_slice.sharpen 1, 0.5
				width = magick_slice.columns
				height = magick_slice.rows
				if @gradient
					magick_slice.matte = true
					gradient_slice = Magick::Image.new(width, height,
						Magick::GradientFill.new(0, 0, width, 0, "##{@gradient[0]}", "##{@gradient[1]}"))
					gradient_slice.matte = true
					magick_slice = gradient_slice.composite(magick_slice, Magick::NorthWestGravity, Magick::CopyOpacityCompositeOp)
				end
				magick_slice.write(@file_name.gsub(/\.png/,"_normal_#{count}.png"))
				magick_slices << @file_name.gsub(/\.png/,"_normal_#{count}.png")
			end
			count += 1
		end
		main_image = Magick::Image.new(@box_width / 5, @box_height / 5) { self.background_color = "transparent" }
		magick_slices.each_with_index do |slice, index|
			slice_image = Magick::ImageList.new(slice){ self.depth = 32 }.pop
			main_image.composite!(slice_image, 0, index * slice_image.rows, Magick::OverCompositeOp)
			FileUtils.rm slice
		end
		main_image.write @file_name
	end

	def prepare_string
		if @float_width > 0
			if @cut > 0
				@words = float(@words, @gd_font, @cut)
			else
				@words = float(@words, @gd_font)
			end
		end
	end

	def dimensions
		string = @words.gsub(/\r/,'')
		string_array = string.split(/\n/)
		@words_array = string_array
		longest_string = ""
		for line in string_array
			reference_box = @gd_font.bounding_rectangle(longest_string)
			testing_box = @gd_font.bounding_rectangle(line)
			reference_width = reference_box[:upper_right][0] - reference_box[:upper_left][0]
			testing_width = testing_box[:upper_right][0] - testing_box[:upper_left][0]
			if testing_width > reference_width
				longest_string = line
			end
		end
		final_box = @gd_font.bounding_rectangle(longest_string)
		final_width = final_box[:upper_right][0] - final_box[:upper_left][0]
		final_height = final_box[:lower_right][1] - final_box[:upper_right][1]
		@box_width = final_width
		@box_height = (@size * 1.4).to_i * 5 * string_array.nitems
		return {
							:width => final_width,
							:height => (@size * 1.4).to_i * 5 * string_array.nitems
		}
	end


	def create_image
		dim = dimensions
		@gd_image = Image::TrueColor.new(dim[:width], dim[:height])
	end

	def create_slice
		dim = dimensions
		Image::TrueColor.new(dim[:width], dim[:height] / @words_array.nitems)
	end

	def float(str, font, cut = 0)
    dest = []
    width = @float_width * 5
    index = 0
    str.split(" ").each do |word|
      dest[index] ||= []
      box_width = string_width((dest[index] + [word]) * ' ')
      if box_width < width
        dest[index] << word
      else
        index += 1
        dest[index] = [word]
     end
    end
    ret = dest.collect{ |line| line * ' ' }.join("\n")
    if cut > 0
      lines = []
      idx = 0
      dest.each do |l|
        lines << l if idx < cut
        idx += 1
      end
      ret = lines.collect{ |line| line * ' '}.join("\n")
    end
    return ret.gsub(/^\n/,"")
  end

	def string_width(str)
		box = @gd_font.bounding_rectangle str
		box[:upper_right].first - box[:upper_left].first
	end
end
