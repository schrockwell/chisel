Gem::Specification.new do |s|
	s.name = 'chisel'
	s.version = '0.0.2'
	s.platform = Gem::Platform::RUBY
	s.author = 'Rockwell Schrock'
	s.email = 'schrockwell@gmail.com'
	s.summary = 'A static Web site generator.'
	s.description = 'Chisel is tool to generate simple, resource-based static Web sites.'
	s.homepage = 'https://github.com/schrockwell/chisel'
	
	s.executables = ['chisel']
	
	s.require_path = 'lib' 
	s.files = Dir.glob("lib/**/*")
	
	s.add_dependency('RedCloth', '>= 4.2.7')
	s.add_dependency('maruku', '>= 0.6.0')
	
end
