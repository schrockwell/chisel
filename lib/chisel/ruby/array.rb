class Array
	def sort_by_method(method_name, ascending=true)
		method_name = method_name.to_sym
		self.sort do |left, right|
			if left.respond_to?(method_name) and right.respond_to?(method_name)
				if ascending
					left.public_send(method_name) <=> right.public_send(method_name)
				else
					right.public_send(method_name) <=> left.public_send(method_name)
				end
			else
				raise "Could not sort items #{left} and #{right}. They do not both respond to method '#{method_name.to_s}'"
			end
		end
	end
	
	def unique(method_name)
		method_name = method_name.to_sym
		values = []
		
		self.each do |item|
			if item.respond_to?(method_name)
				value = item.send(method_name)
				values << value unless values.index(value)
			else
				raise "Could not pick out unique items: #{item} does not respond to method '#{method_name}'"
			end
		end
		
		values
	end
end