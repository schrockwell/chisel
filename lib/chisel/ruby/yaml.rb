module YAML
	module Syck
		def YAML.remove_header(string)
			matches = string.match(/---\n(.*)\n---\n(.*)/m)
			return string unless matches and matches.size > 2
			matches[2]
		end

		def YAML.header_string(string)
			matches = string.match(/---\n(.*)\n---/m)
			return '' unless matches and matches.size > 1
			matches[1]
		end
	
		def YAML.load_header(string)
			header_string = YAML.header_string(string)
			return {} if header_string == ''
			YAML.load(header_string)
		end
	end
end