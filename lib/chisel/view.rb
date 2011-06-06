require 'yaml'
require 'erb'
require 'pathname'

class View
	
	MarkupExtensions = ['erb', 'md', 'textile']
	
	attr_accessor :type, :path, :view, :header, :site_dir, :resource, :raw_content
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
		@header = yaml_header(@raw_content).symbolize_keys
		@erb = ERB.new(remove_yaml_header(@raw_content))
		@@cache << self
		
	end
	
	def matches(options = {})
		
		return true if options.key?(:resource) and @type == :resource and @view == options[:view] and @resource == options[:resource]
		return true if options.key?(:layout) and @type == :layout and @view == options[:layout]
		return true if @path == options[:path]
		
		return false
		
	end
	
	def run(options = {})
		view_relative_dir = @path.relative_path_from(@site_dir).dirname
		file_output_dir = @site_dir.output_dir.join(view_relative_dir)
		output_path = file_output_dir.join(output_basename)
		file_output_dir.mkpath
		
		return if @@output_paths.index(output_path) or output_path.exist?
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
		
		# Maintin the binding if we were passed one; otherwise,
		# create a brand new binding from our @header info
		
		if options[:binding]
			bynding = options[:binding]
			
			# Overwrite layout that was passed in
			if @header[:layout]
				bynding.eval("layout = '#{@header[:layout]}'")
			else
				bynding.eval("layout = nil")
			end
			
		else
			
			if options[:locals]
				vars = @header.merge(options[:locals])
			else
				vars = @header.clone
			end
			vars[:content] = nil
			vars[:layout] = nil unless vars.key?(:layout)
			
			if options[:resource]
				resource_key = options[:resource].resource_type.to_sym
				vars[resource_key] = options[:resource]
				vars[:resource] = options[:resource] # alias as "resource"
			end
			
			bynding = vars.to_binding(helper)
			
		end
		
		# Evaluate the content with the binding
		
		content = remove_yaml_header(@raw_content)
		
		markup_extensions.reverse.each do |extension|
			case extension.downcase
			when 'erb'
				content = @erb.result(bynding)
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
		
		if bynding.eval('layout')
			bynding.eval("content = <<EOS\n#{content}\nEOS")
			layout_view = View.fetch(:layout => bynding.eval('layout'), :site_dir => @site_dir)
			content = layout_view.evaluate(output_path, :binding => bynding)
		end
		
		content
	end
	
private
	
	def yaml_header(file)
		matches = file.match(/---\n(.*)\n---/m)
		return {} unless matches and matches.size > 1
		YAML.load(matches[1])
	end
	
	def remove_yaml_header(file)
		matches = file.match(/---\n(.*)\n---\n(.*)/m)
		return file unless matches and matches.size > 2
		matches[2]
	end
	
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
