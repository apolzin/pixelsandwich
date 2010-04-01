require 'lib/sandwich_layer.rb'
require 'dictionary'

class PixelSandwich

	attr_accessor :layers, :size, :file_name

	def initialize(size=0)
		@size = size
		@layers = Dictionary.new
	end

	def add_layer(name,type,options={})
		unless @layers.has_key?(name)
			case type
				when :text
					@layers[name] = SandwichLayerText.new(options)
				when :image
					@layers[name] = SandwichLayerImage.new(options)
			end
		end
	end
	def render
		@layers.each do |key,value|
			@layers[key].render
		end
		if @size == 0
			image = Magick::ImageList.new(@layers.shift[1].file_name).pop
		else
			image = Magick::Image.new(@size[0],@size[1])
		end
		@layers.each do |key,value|
			composite_image = Magick::ImageList.new(@layers[key].file_name).pop
			image.composite!(composite_image, @layers[key].position[0], @layers[key].position[1], Magick::OverCompositeOp)
		end
		image.write(@file_name)
	end

end
