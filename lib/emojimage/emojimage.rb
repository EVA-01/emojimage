require "gemoji"
require "json"
require "oily_png"

module Emojimage
	extend self

	@@emoji = Emoji.all.select { |char| !char.custom? }
	@@where = File.expand_path "../", File.dirname(__FILE__)
	@@info = false
	##
	# All the emoji
	def emoji
		@@emoji
	end
	##
	# Grab emoji image
	def where e
		if e.class == Hash
			address = e['filename']
		elsif e.class == Emoji::Character
			address = e.image_filename
		else
			raise "Unknown emoji representation passed to Emojimage.where"
		end
		within "../public/images/emoji/#{address}"
	end
	##
	# Find relative path.
	def within path
		File.expand_path path, @@where
	end
	##
	# Average of an array of colors. Returns `ChunkyPNG::Color::TRANSPARENT` if `transparentBlock` is true and the colors are all transparent. Blends the transparent/semi-transparent with `blend` color.
	def average colors, transparentBlock = false, blend = ChunkyPNG::Color::WHITE
		color = [0.0,0.0,0.0,0.0]
		count = 0.0
		for pxl in colors
			weight = ((255 - (ChunkyPNG::Color.a pxl)) / 255.0).to_f
			color[0] += ((1.0 - weight) * (ChunkyPNG::Color.r pxl).to_f + weight * (ChunkyPNG::Color.r blend).to_f)
			color[1] += ((1.0 - weight) * (ChunkyPNG::Color.g pxl).to_f + weight * (ChunkyPNG::Color.g blend).to_f)
			color[2] += ((1.0 - weight) * (ChunkyPNG::Color.b pxl).to_f + weight * (ChunkyPNG::Color.b blend).to_f)
			color[3] += ChunkyPNG::Color.a pxl
			count += 1.0
		end
		if transparentBlock and color[3] == 0.0
			ChunkyPNG::Color::TRANSPARENT
		else
			ChunkyPNG::Color.rgb (color[0]/count).round, (color[1]/count).round, (color[2]/count).round
		end
	end
	##
	# Get the overall average color of an image.
	def analyze img
		average img.pixels
	end
	##
	# Has this been set up with the current `blend` setting?
	def setup? blend
		gemojiV = "#{Gem.loaded_specs['gemoji'].version.to_s}\n#{blend}"
		lastImport = File.open(within("../public/data/.last"), 'rb') { |f| f.read }
		lastImport == gemojiV
	end
	##
	# Sets up the enviroments by grabbing the emoji images and setting emoji info.
	def setup blend
		gemojiV = "#{Gem.loaded_specs['gemoji'].version.to_s}\n#{blend}"
		unless setup? blend
			system("cd #{within "../"} && rake emoji")
			# puts "Initialized emoji images"
			codify blend
			File.open(within("../public/data/.last"), "w+") { |f| f.write gemojiV }
			# puts "Analyzed emoji images"
		end
	end
	##
	# Grab emoji info. If it doesn't exist, return `false`.
	def emojinfo
		if @@info == false
			if File.exist?(within("../public/data/emoji.json"))
				@@info = JSON.parse(File.open(within("../public/data/emoji.json"), 'rb') { |f| f.read })
			else
				@@info = false
			end
		end
		@@info
	end
	##
	# Splits a hex value in case there are two hexes inside
	def unpackhex c
		c.hex_inspect.split '-'
	end
	##
	# Create JSON file with info about emoji.
	def codify blend = ChunkyPNG::Color::WHITE
		res = {"characters" => []}
		for e in @@emoji
			png = chunkemoji e
			res["characters"] << {
				"filename" => e.image_filename,
				"value" => average(png.pixels, false, blend),
				"unicode" => e.unicode_aliases.first,
				"key" => unpackhex(e)
			}
		end
		File.open(within("../public/data/emoji.json"), "w+") { |f| f.write res.to_json }
	end
	##
	# Get distance between two colors.
	def compare c1, c2
		Math.sqrt((ChunkyPNG::Color.r(c1)-ChunkyPNG::Color.r(c2))**2+(ChunkyPNG::Color.g(c1)-ChunkyPNG::Color.g(c2))**2+(ChunkyPNG::Color.b(c1)-ChunkyPNG::Color.b(c2))**2)
	end
	##
	# Get emoji that corresponds to `color`. `blend` represents a color to blend with for transparency (in other words, a background color).
	def find color, blend
		setup blend
		data = emojinfo
		if color == ChunkyPNG::Color::TRANSPARENT
			false
		else
			data["characters"].min_by { |char| compare color, char["value"] }
		end
	end
	##
	# Get `ChunkyPNG::Image` from emoji
	def chunkemoji e
		ChunkyPNG::Image.from_file(where e)
	end
end