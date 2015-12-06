require 'thor'

module Emojimage
	class CLI < Thor
		option :output, :required => true, :aliases => "-o", :type => :string, :desc => "Output filename. If an image, must be PNG."
		option :type, :required => true, :aliases => "-t", :type => :string, :enum => ["text", "html", "image"], :desc => "Output type."
		option :size, :default => 4, :aliases => "-s", :type => :numeric, :desc => "Emoji size"
		option :transparency, :default => true, :aliases => "-T", :type => :boolean, :desc => "Don't convert wholly transparent blocks to emoji. Retain the transparency instead."
		option :wrap, :default => true, :aliases => "-w", :type => :boolean, :desc => "Wraps HTML with <pre><code></code></pre>"
		option :blend, :default => [255, 255, 255], :aliases => "-b", :type => :array, :desc => "Background color. Doesn't actually change transparency, just emoji selection."
		desc "cast INPUT", "Convert image to emoji"
		##
		# CLI option to convert and save image.
		def cast(image)
			c = []
			for comp in options['blend']
				c << comp.to_i
			end
			if c.length == 1
				color = ChunkyPNG::Color.rgb(c[0], c[0], c[0])
			elsif c.length == 3
				color = ChunkyPNG::Color.rgb(c[0], c[1], c[2])
			else
				raise "Bad RGB in blend option"
			end
			spell = Emojimage::Converted.new image, options['size']
			spell.run options['transparency'], color
			spell.save options['output'], options['type'].to_sym, options['wrap']
		end
		default_task :cast
	end
end