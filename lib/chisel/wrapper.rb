require 'fileutils'
require 'json'
require 'chisel/resource'
require 'chisel/site_directory'
require 'chisel/view'
require 'chisel/view_helper'

require 'chisel/ruby/array'
require 'chisel/ruby/hash'
require 'chisel/ruby/string'
require 'chisel/ruby/yaml'

module Chisel
	class Wrapper
		attr_accessor :site_dir
	
		def initialize(site_dir)
			@site_dir = SiteDirectory.new(site_dir)
			require_rb(@site_dir.resource_dir)
		end

		def run(dir = @site_dir)
			@site_dir.clear_output_dir
		
			# Get all views in the root site directory as well
			# as any subdirectories (recursive). Don't include
			# any files or folders beginning with an underscore.
			view_paths = Pathname.glob(@site_dir.join('[^_]*.*'))
			view_paths += Pathname.glob(@site_dir.join('[^_]**/**/*.*'))
		
			view_paths.each do |view_path|
				if view_path.extname == '.erb'
					view = View.fetch(:path => view_path, :site_dir => @site_dir)
					view.run
				else
					output_path = @site_dir.output_dir.join(view_path)
					output_path.dirname.mkpath
					FileUtils.cp(view_path, output_path)
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
end