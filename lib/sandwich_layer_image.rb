class SandwichLayerImage < SandwichLayer
	DEFAULTS = {
		:cache_dir => '/tmp/pixelsandwich/cache/imagelayers/',
		:source_image => false
	}

	attr_accessor :cache_dir, :file_name, :source_image, :image_width, :image_height

	def initialize(options={})
		options = DEFAULTS.merge options

		options.each do |key, value|
			self.send(key.to_s + "=", value)
		end
		create_directories
		@file_name = @cache_dir + Digest::MD5.hexdigest(options.to_s) << '.png'
		#super
	end

	def create_directories
		FileUtils.mkdir_p @cache_dir unless File.exists? @cache_dir
	end

	def render
		if File.exist?(@source_image)
			unless File.exist?(@file_name)
				magick_image = Magick::ImageList.new(@source_image).pop
				magick_image.write(@file_name)
			end
		end
	end

end
