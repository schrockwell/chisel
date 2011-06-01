class Resource
	
	@@cache = {}
	
	def id
		raise "You must implement #{self.class.name}.id"
	end
	
	def self.all
		raise "You must implement #{self.class.name}.all"
	end
	
	def resource_type
		self.class.name.underscore
	end
	
	def inspect
		File.join(*self.id)
	end
	
	def cache(*keys)
		@cache ||= {}
		cached = true
		keys.each { |key| cached &= @cache.key?(key) }
		return keys.map { |key| @cache[key] } if cached
		if keys.size == 1
			results = yield
			@cache[keys[0]] == results
		else
			results = [*yield]
			keys.each_index { |i| @cache[keys[i]] = results[i] }
		end
		results
	end
	
	def self.class_cache(*keys)
		cached = true
		keys.each { |key| cached &= @@cache.key?(key) }
		return keys.map { |key| @@cache[key] } if cached
		if keys.size == 1
			results = yield
			@@cache[keys[0]] == results
		else
			results = [*yield]
			keys.each_index { |i| @@cache[keys[i]] = results[i] }
		end
		results
	end
	
	def self.find_in(resources, parameters={})
		return resources if parameters == {}
		results = []
	
		resources.each do |resource|
			matches = true
			parameters.each do |param, value|
				param = param.to_sym
				if resource.respond_to?(param)
					param_value = resource.public_send(param)
					if param_value != value
						matches = false
						break
					end
				end
			end
			results << resource if matches
		end
		results
	end
	
	def self.find(parameters={})
		self.find_in(self.all, parameters)
	end
end
