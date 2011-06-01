class Hash
	
	def symbolize_keys
		self.inject({}) do |memo,(k,v)| 
			if v.is_a?(Hash)
				memo[k.to_sym] = v.symbolize_keys
			else
				memo[k.to_sym] = v
			end
			memo
		end
	end
	
	def to_binding(object = Object.new)
		object.instance_eval("def binding_for(#{keys.join(",")}) binding end")
		# object.instance_eval('def method_missing(method_name); nil; end')
		object.binding_for(*values)
	end
	
end
