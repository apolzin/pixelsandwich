class SandwichLayer
	require 'rubygems'
	require 'RMagick'
	require 'gd2'
	require 'fileutils'
	require 'digest'
	require 'sandwich_layer_text'
	require 'sandwich_layer_image'

	attr_accessor :opacity, :position
	LAYERDEFAULTS = {
		:opacity => 1,
		:position => [0,0]
	}
	def initialize(layeroptions={})
		layeroptions = LAYERDEFAULTS.merge layeroptions

		layeroptions.each do |key,value|
			self.send(key.to_s + "=", value)
		end
	end
end
