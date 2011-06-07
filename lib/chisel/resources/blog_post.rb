require 'pathname'
require 'RedCloth'

module Chisel
	module Resources
		class BlogPost < Resource
			attr_accessor :year, :month, :day, :url_title, :title, :content
			
			def initialize(filename)
				filename = Pathname.new(filename)
				tokens = filename.basename.to_s.split('-')
				@year, @month, @day = tokens[0..2]
				@url_title = tokens[3..-1].join('-').gsub('.textile', '')
				
				@content = File.read(filename)
				header = YAML.load_header(@content)
				@content = YAML.remove_header(@content)
				@content = RedCloth.new(@content).to_html
				
				@title = header['title']
			end
	
			def self.all
				post_filenames = Dir.glob('_posts/*.textile').sort
				post_filenames.map { |filename| Post.new(filename) }
			end
			
			def id
				[@year, @month, @day, @url_title]
			end
		end
	end
end