require 'fileutils'
require 'pathname'
require 'yaml'

module Chisel
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
			FileUtils.rm_r(output_dir) if File.exists?(output_dir) and @config['replace_output_dir'] != false
			FileUtils.mkdir_p(output_dir)
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
	
		def page_output_path(page, view_output_dir)
			page = view_with_extension(page)
			self.site_relative_path(page, view_output_dir)
		end

		def layout_view_path(layout_name)
			self.layout_dir.join("#{view_with_extension(layout_name).to_s}.erb")
		end
	
		def view_path(view)
			self.view_dir.join("#{view_with_extension(view)}.erb")
		end
		
		def site_relative_path(relative_path, view_output_dir)
			if relative_path[0] == '/'
				self.output_dir.join(relative_path[1..-1])
			else
				view_output_dir.join(relative_path)
			end
		end
	
		def view_with_extension(view)
			view = "#{view}index" if view[-1] == '/'
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
	
		def create_resource(name)
			name = name.underscore if name.camelized?
			
			# Create resource.rb file
			
			resource_template_filename = Pathname.new(__FILE__).dirname.join('templates', 'resource.rb')
			resource_template = File.read(resource_template_filename)
			resource_template.gsub!('{NAME}', name.camelize)
			
			resource_filename = self.join('_resources', "#{name}.rb")
			File.open(resource_filename, 'w') { |f| f.write(resource_template) }
			
			# Create resource index.html file
			
			self.join('_views', name).mkpath
			
			index_template_filename = Pathname.new(__FILE__).dirname.join('templates', 'resource_index.html.erb')
			index_template = File.read(index_template_filename)
			index_template.gsub!('{NAME}', name.camelize)
			
			index_filename = self.join('_views', name, 'index.html.erb')
			File.open(index_filename, 'w') { |f| f.write(index_template) }
			
		end
	
	end
end