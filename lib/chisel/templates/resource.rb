class {NAME} < Chisel::Resource
	
	def initialize
		# TODO: Implement a custom {NAME} resource class constructor
	end
	
	def self.all
		raise 'You must implement {NAME}.all to return an array of all {NAME} resources'
	end
	
	def id
		raise 'You must implement {NAME}.id to return an array that uniquely identifies this resource'
	end
	
end