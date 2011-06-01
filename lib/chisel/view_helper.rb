class ViewHelper
	attr_accessor :site_dir, :output_path
	
	def initialize(site_dir, output_path)
		@site_dir = site_dir
		@output_path = output_path
	end
	
	def render(view, options = {})
		locals = options[:locals] || {}
		
		template = View.fetch(:view => view, :site_dir => @site_dir)
		template.evaluate(@output_path, :locals => locals)
	end
	
	
	def link_to_resource(resource, text, options = {})
		view = options[:view] || 'index'
		
		view_path = @site_dir.resource_view_output_path(resource, view)
		href = view_path.relative_path_from(@output_path.dirname).to_s
		
		# Initialize the view template
		template = View.fetch(:resource => resource.resource_type, :view => view, :site_dir => @site_dir)
		
		# Compute the output path for this specific resource
		output_path = @site_dir.resource_view_output_path(resource, view)
		
		# Now run the view template against this resource
		template.run(output_path, :resource => resource)
		
		link_to(href, text, options)
	end
	
	def link_to_page(page, text, options = {})
		page_output_path = @site_dir.page_output_path(page)
		href = page_output_path.relative_path_from(@output_path.dirname).to_s
		
		link_to(href, text, options)
	end
	
	def path_to(site_relative_path)
		@site_dir.output_dir.join(site_relative_path).relative_path_from(@output_path.dirname)
	end

	def link_to(href, text, options = {})
		if options[:html]
			attribute_string = ''
			options[:html].each do |k, v| 
				attribute_string += " #{k}=\"#{v}\"" if LinkAttributes.index(k.to_s.downcase) 
			end
		end
		
		href = href[0..-11] if href.end_with?('index.html') and href != 'index.html'
		
		"<a href=\"#{href}\"#{attribute_string}>#{text}</a>"
	end
end
