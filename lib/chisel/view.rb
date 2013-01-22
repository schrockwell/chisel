require 'yaml'
require 'pathname'
require 'erb'

module Chisel
	class View
	
		MarkupExtensions = ['erb', 'md', 'textile']
	
		attr_accessor :type, :path, :view, :site_dir, :resource, :raw_content
		@@cache = []
		@@output_paths = []
	
		def self.fetch(options={})
			@@cache.each do |view|
				return view if view.matches(options)
			end
		
			return View.new(options)
		end
	
		def initialize(options={})
		
			# Do not call the initializer directly; use View.fetch(options)
			# to take advantage of view caching
		
			@path = Pathname.new(options[:path]) if options[:path]
			@site_dir = SiteDirectory.new(options[:site_dir]) if options[:site_dir]
			
			if options[:resource]
				@type = :resource
				@resource = options[:resource]
				@view = options[:view]
				@path = @site_dir.resource_type_view_path(@resource, @view)
			elsif options[:layout]
				@type = :layout
				@view = options[:layout]
				@path = @site_dir.layout_view_path(@view)
			elsif options[:view]
				@view = options[:view]
				@path = @site_dir.view_path(@view)
			end

			raise 'Cannot initialize view without a path' unless @path
		
			@raw_content = File.read(@path)
			@@cache << self
		
		end
	
		def matches(options = {})
		
			return true if options.key?(:resource) and @type == :resource and @view == options[:view] and @resource == options[:resource]
			return true if options.key?(:layout) and @type == :layout and @view == options[:layout]
			return true if @path == options[:path]
		
			return false
		
		end
	
		def run(options = {})
			if options[:output_path] then
				output_path = options[:output_path]
			else
				view_relative_dir = @path.relative_path_from(@site_dir).dirname
				file_output_dir = @site_dir.output_dir.join(view_relative_dir)
				file_output_dir.mkpath
				output_path = file_output_dir.join(output_basename)
			end
		
			return if @@output_paths.index(output_path)
			@@output_paths << output_path
		
			FileUtils.mkdir_p(output_path.dirname)
		
			result = evaluate(output_path, options)
		
			f = File.new(output_path, 'w')
			f.write(result)
			f.close
		
			result
		end
	
		def evaluate(output_path, options = {})
		
			if @type == :layout
				puts "Evaluating layout for #{output_path}..."
			else
				puts "Evaluating #{output_path}..."
			end
			
			helper = ViewHelper.new(@site_dir, output_path)
			
			# First evaluate header as ERB if necessary
			
			header_vars = {}
			if options[:resource]
				resource_key = options[:resource].resource_type.to_sym
				header_vars[resource_key] = options[:resource]
				header_vars[:resource] = options[:resource]
			end
			
			header_binding = header_vars.to_binding(helper)
			header_string = ERB.new(YAML.header_string(@raw_content)).result(header_binding)
			if header_string == ''
				header = {}
			else
				header = YAML.load(header_string).symbolize_keys
			end
			
			# Maintin the binding if we were passed one; otherwise,
			# create a brand new binding from our header info
		
			if options[:binding]
				content_binding = options[:binding]
			
				# Overwrite layout that was passed in
				if header[:layout]
					content_binding.eval("layout = '#{header[:layout]}'")
				else
					content_binding.eval("layout = nil")
				end
			
			else
			
				if options[:locals]
					vars = header.merge(options[:locals])
				else
					vars = header.clone
				end
				vars[:content] = nil
				vars[:layout] = nil unless vars.key?(:layout)
			
				if options[:resource]
					resource_key = options[:resource].resource_type.to_sym
					vars[resource_key] = options[:resource]
					vars[:resource] = options[:resource] # alias as "resource"
				end
			
				content_binding = vars.to_binding(helper)
			
			end
		
			# Evaluate the content with appropriate markup and ERB
			
			content = YAML.remove_header(@raw_content)
			
			markup_extensions.reverse.each do |extension|
				case extension.downcase
				when 'erb'
					content = ERB.new(content).result(content_binding)
				when 'textile'
					begin
						require 'RedCloth'
					rescue LoadError
						puts "
The RedCloth gem is required to evaluate Textile markup. Please run:

    gem install RedCloth"
						exit
					end
					content = RedCloth.new(content).to_html
				when 'md'
					begin
						require 'maruku'
					rescue LoadError
						puts "
The Maruku gem is required to evaluate Markdown markup. Please run:

    gem install maruku"
						exit
					end
					content = Maruku.new(content).to_html
				end
			end
		
			# Now evaluate the layout
		
			if content_binding.eval('layout')
				content_binding.eval("content = <<EOS\n#{content}\nEOS")
				layout_view = View.fetch(:layout => content_binding.eval('layout'), :site_dir => @site_dir)
				content = layout_view.evaluate(output_path, :binding => content_binding)
			end
		
			content
		end
	
	private
	
		def markup_extensions
			tokens = Pathname.new(@path).basename.to_s.split('.')
			return nil if tokens.length == 1
		
			i = tokens.length
			tokens.reverse.each do |token|
				break unless MarkupExtensions.index(token)
				i = i - 1
			end
		
			return tokens[i..-1].map { |t| t.downcase }
		end
	
		def output_basename
			return @path.basename unless markup_extensions
			extensions = '.' + markup_extensions.join('.')
			return @path.basename(extensions)
		end
	
	end
end