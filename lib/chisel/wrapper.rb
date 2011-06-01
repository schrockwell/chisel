require 'fileutils'
require 'json'
require 'chisel/resource'
require 'chisel/site_directory'
require 'chisel/view'
require 'chisel/view_helper'

require 'chisel/ruby/array'
require 'chisel/ruby/hash'
require 'chisel/ruby/string'

class Wrapper
	attr_accessor :site_dir
	
	def initialize(site_dir)
		@site_dir = SiteDirectory.new(site_dir)
		require_rb(@site_dir.resource_dir)
	end

	def run(dir = @site_dir)
		@site_dir.clear_output_dir
		
		# Get all views in the root site directory as well
		# as any subdirectories (recursive)
		view_paths = Pathname.glob(@site_dir.join('[^_]*.*'))
		view_paths += Pathname.glob(@site_dir.join('[^_]**/**/*.*'))
		
		view_paths.each do |view_path|	
			output_filename = view_path.basename('.erb')
			view_relative_dir = view_path.relative_path_from(@site_dir).dirname
			file_output_dir = @site_dir.output_dir.join(view_relative_dir)
			output_path = file_output_dir.join(output_filename)
			file_output_dir.mkpath
			
			if view_path.extname == '.erb'
				view = View.fetch(:path => view_path, :site_dir => @site_dir)
				view.run(output_path)
			elsif not view_path.directory?
				FileUtils.copy(view_path.expand_path, output_path)
			end
		end
	end

private
	
	def require_rb(path)
		Dir["#{path}/*.rb"].each do |filename|
			require File.expand_path(filename)
		end
	end
end
