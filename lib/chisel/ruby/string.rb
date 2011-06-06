class String
	
	def underscored?
		self[0].downcase == self[0]
	end
	
	def camelized?
		self[0].upcase == self[0]
	end
	
	# Converts 'Foo::HerpDerp' to 'foo/herp_derp'
	def underscore
		tokens = self.split('::')
		if tokens.count > 1
			return (tokens.map { |token| token.underscore }).join('/')
		end
		
		result = ''
		for i in (0..(self.length - 1))
			result << '_' if self[i] == self[i].upcase and i != 0
			result << self[i].downcase
		end
		result
	end
	
	# Converts 'foo/herp_derp' to 'Foo::HerpDerp'
	def camelize
		tokens = self.split('/')
		if tokens.count > 1
			return (tokens.map { |token| token.camelize }).join('::')
		end
		
		result = ''
		capitalize = true
		
		for i in (0..(self.length - 1))
			if self[i] == '_'
				capitalize = true
			elsif capitalize
				capitalize = false
				result << self[i].upcase
			else
				result << self[i]
			end
		end
		result
	end
	
end
