require 'fileutils'
require 'pathname'
require 'yaml'

class SiteDirectory < Pathname
	attr_accessor :config
	
	@config = {}

	def initialize(site_dir)
		super
		config_path = self.join('_config.yml')
		if config_path.exist?
			@config = YAML::load_file(config_path) || {}
		end
	end
	
	def output_dir
		if @config['output_dir']
			dir = Pathname.new(@config['output_dir']).expand_path(self)
			if dir.absolute?
			return dir
			else
			return self.join(dir)
			end
		else
			return self.join('_output')
		end
	end
	
	def resource_dir
		self.join('_resources')
	end
	
	def view_dir
		self.join('_views')
	end
	
	def layout_dir
		self.view_dir.join('_layout')
	end
	
	def clear_output_dir
		FileUtils.rm_r(output_dir) if File.exists?(output_dir)
		FileUtils.mkdir(output_dir)
	end
	
	def require_resources
		path = self.resource_dir.join("*.rb").expand_path
		Dir[path].each do |resource_filename|
			require resource_filename
		end
	end
	
	def resource_type_view_path(resource_type, view)
		self.view_dir.join(resource_type.to_s, "#{view_with_extension(view)}.erb")
	end
	
	def resource_view_output_path(resource, view)
		self.output_dir.join(*resource.id, view_with_extension(view))
	end
	
	def page_output_path(page)
		page = view_with_extension(page)
		self.output_dir.join(page)
	end

	def layout_view_path(layout_name)
		self.layout_dir.join("#{view_with_extension(layout_name).to_s}.erb")
	end
	
	def view_path(view)
		self.view_dir.join("#{view_with_extension(view)}.erb")
	end
	
	def view_with_extension(view)
		return "#{view}.html" if File.basename(view).split('.').count < 2
		view
	end
	
	def self.create(dest)
		dir = Pathname.new(__FILE__).dirname
		src = dir.join('new_site')
		dest = Pathname.new(dest)
		
		FileUtils.cp_r(src.to_s + '/.', dest)
		
		dest.join('_resources').mkpath
		dest.join('_views', '_resource').mkpath
	end
	
end
