module Emojimage
	##
	# The canvas
	class Converted
		attr_reader :image, :size, :emoji
		##
		# `img` is the input image. Should be either a file path or a `ChunkyPNG::Image`. `size` is the chunk size that will be converted to emoji.
		def initialize img, size = 4
			if img.class == String
				img = ChunkyPNG::Image.from_file img
			elsif img.class != ChunkyPNG::Image
				raise "Unknown image representation"
			end
			if size < 1
				raise "Use a size more than 0"
			end
			@size = size
			@emoji = []
			@image = nil
			@original = img
		end
		##
		# Run the conversion. If `transparentBlock` is true, the image will retain transparency. If false, wholly transparent areas will be emoji. Blends the transparent/semi-transparent with `blend` color.
		def run transparentBlock = false, blend = ChunkyPNG::Color::WHITE
			img = @original
			w = img.width
			h = img.height
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
					value = Emojimage.average pxls, transparentBlock, blend
					if value == ChunkyPNG::Color::TRANSPARENT
						rowmoji << " "
					else
						found = Emojimage.find value, blend
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
		##
		# Outputs the emoji as raw text. **Run `run` first.**
		def text
			raise "Use 'run' first" if @image == nil
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
		##
		# Outputs the emoji as HTML. If `wrap` is false, the emoji will not be placed in a code-block.
		def html wrap = true
			raise "Use 'run' first" if @image == nil
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
		##
		# Save to `fn`. `what` is one of `:image`, `:text`, `:html`. `wrap` affects `:html` output.
		def save fn, what = :image, wrap = true
			raise "Use 'run' first" if @image == nil
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