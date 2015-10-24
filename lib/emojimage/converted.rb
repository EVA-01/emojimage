module Emojimage
	class Converted
		attr_reader :image, :size, :emoji
		def initialize img, size = 4, transparentBlock = false, blend = ChunkyPNG::Color::WHITE
			if img.class == String
				img = ChunkyPNG::Image.from_file img
			elsif img.class != ChunkyPNG::Image
				raise "Unknown image representation in Emojimage.cast"
			end
			if size < 1
				raise "Use a size more than 0"
			end
			@size = size
			w = img.width
			h = img.height
			@emoji = []
			@image = ChunkyPNG::Image.new(w, h)
			(0...h).step(size).each do |row|
				rowmoji = []
				(0...w).step(size).each do |column|
					pxls = []
					for y in (0...size)
						if img.include_y?(y + row)
							for x in (0...size)
								pxls << img[x + column, y + row] if img.include_x?(x + column)
							end
						end
					end
					value = Emojimage.average pxls, transparentBlock
					if value == ChunkyPNG::Color::TRANSPARENT
						rowmoji << " "
					else
						found = Emojimage.find value
						rowmoji << found
						emoji = Emojimage.chunkemoji(found).resample_nearest_neighbor size, size
						for y in 0...size
							if img.include_y?(y + row)
								for x in 0...size
									if img.include_x?(x + column)
										@image[x + column, y + row] = emoji[x, y]
									end
								end
							end
						end
					end
				end
				@emoji << rowmoji
			end
		end
		def text
			rows = []
			for row in @emoji
				txt = ""
				for col in row
					if col == " "
						txt += " "
					else
						txt += col['unicode']
					end
				end
				rows << txt
			end
			rows.join "\n"
		end
		def html wrap = false
			rows = []
			for row in @emoji
				txt = ""
				for col in row
					if col == " "
						txt += "&nbsp;"
					else
						for h in col['key']
							txt += "&\##{h.to_i(16)};"
						end
					end
				end
				rows << txt
			end
			if wrap
				"<code><pre style='font-family: \"Apple Color Emoji\"; font-size: #{@size}px; line-height:1em'>#{rows.join "\n"}</pre></code>"
			else
				rows.join "\n"
			end
		end
		def save fn, what = :image, wrap = false
			case what
			when :image
				@image.save fn
			when :text
				File.open(fn, "w+") { |f| f.write text }
			when :html
				File.open(fn, "w+") { |f| f.write html(wrap) }
			end
		end
	end
end