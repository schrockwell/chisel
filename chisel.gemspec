# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

Gem::Specification.new do |s|
	s.name = 'chisel'
	s.version = '0.0.1'
	s.platform = Gem::Platform::RUBY
	s.author = 'Rockwell Schrock'
	s.email = 'schrockwell@gmail.com'
	s.summary = 'A static Web site generator.'
	s.description = 'Chisel is tool to generate simple, resource-based static Web sites.'
	
	s.executables = ['chisel']
	
	s.require_path = 'lib' 
	s.files = Dir.glob("lib/**/*")
end