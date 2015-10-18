require "emojimage/version"
require "gemoji"
require "json"
require "oily_png"

module Emojimage
	extend self

	@@emoji = Emoji.all.select { |char| (char.image_filename =~ /unicode/) != nil }
	@@where = File.dirname(__FILE__)
	@@info = false
	def emoji
		@@emoji
	end
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
	def within path
		File.expand_path path, @@where
	end
	def average colors, transparentBlock = false
		color = [0.0,0.0,0.0,0.0]
		count = 0
		for pxl in colors
			weight = ((255 - (ChunkyPNG::Color.a pxl)) / 255.0).to_f
			color[0] += ((1 - weight) * (ChunkyPNG::Color.r pxl) + weight * 255)
			color[1] += ((1 - weight) * (ChunkyPNG::Color.g pxl) + weight * 255)
			color[2] += ((1 - weight) * (ChunkyPNG::Color.b pxl) + weight * 255)
			color[3] += ChunkyPNG::Color.a pxl
			count += 1
		end
		if transparentBlock and color[3] == 0.0
			ChunkyPNG::Color::TRANSPARENT
		else
			ChunkyPNG::Color.rgb (color[0]/count.to_f).round, (color[1]/count.to_f).round, (color[2]/count.to_f).round
		end
	end
	def analyze img
		average img.pixels
	end
	def setup?
		gemojiV = Gem.loaded_specs['gemoji'].version.to_s
		lastImport = File.open(within("../public/data/.last"), 'rb') { |f| f.read }
		lastImport == gemojiV
	end
	def setup
		gemojiV = Gem.loaded_specs['gemoji'].version.to_s
		unless setup?
			system("cd #{within "../"} && rake emoji")
			puts "Initialized emoji images"
			codify
			File.open(within("../public/data/.last"), "w+") { |f| f.write gemojiV }
			puts "Analyzed emoji images"
		end
	end
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
	def codify
		res = {"characters" => []}
		for e in @@emoji
			png = chunkemoji e
			res["characters"] << {
				"filename" => e.image_filename,
				"value" => analyze(png)
			}
		end
		File.open(within("../public/data/emoji.json"), "w+") { |f| f.write res.to_json }
	end
	def compare c1, c2
		Math.sqrt((ChunkyPNG::Color.r(c1)-ChunkyPNG::Color.r(c2))**2+(ChunkyPNG::Color.g(c1)-ChunkyPNG::Color.g(c2))**2+(ChunkyPNG::Color.b(c1)-ChunkyPNG::Color.b(c2))**2)
	end
	def find color
		data = emojinfo
		if data == false
			setup
			data = emojinfo
		end
		if color == ChunkyPNG::Color::TRANSPARENT
			false
		else
			data["characters"].min_by { |char| compare color, char["value"] }
		end
	end
	def chunkemoji e
		ChunkyPNG::Image.from_file(where e)
	end
	def cast img, size = 4, transparentBlock = false
		if img.class == String
			img = ChunkyPNG::Image.from_file img
		elsif img.class != ChunkyPNG::Image
			raise "Unknown image representation in Emojimage.cast"
		end
		if size < 4
			raise "Use a size more than 3 in Emojimage.cast"
		end
		w = img.width
		h = img.height
		nu = ChunkyPNG::Image.new(w, h)
		(0...h).step(size).each do |row|
			(0...w).step(size).each do |column|
				pxls = []
				for y in (0...size)
					if img.include_y?(y + row)
						for x in (0...size)
							pxls << img[x + column, y + row] if img.include_x?(x + column)
						end
					end
				end
				value = average pxls, transparentBlock
				unless value == ChunkyPNG::Color::TRANSPARENT
					found = find value
					emoji = chunkemoji(found).resample_nearest_neighbor size, size
					for y in 0...size
						if img.include_y?(y + row)
							for x in 0...emoji.width
								if img.include_x?(x + column)
									nu[x + column, y + row] = emoji[x, y]
								end
							end
						end
					end
				end
			end
		end
		nu
	end
end