# Railspdf
# require 'pdf/writer'

module RailsPDF
  
 	#this code comes from http://wiki.rubyonrails.com/rails/pages/HowtoGeneratePDFs 	
	class PDFRender
		PAPER = 'Letter'
    	#include ApplicationHelper

    	def initialize(action_view)
      		@action_view = action_view
    	end

    
	    def render(template, local_assigns = {})
	    	
	    	#get the instance variables setup
	    	
        @action_view.controller.instance_variables.each do |v|
        	instance_variable_set(v, @action_view.controller.instance_variable_get(v))
		    end
			  @rails_pdf_name = "Default.pdf" if @rails_pdf_name.nil?
				
    		@action_view.controller.headers["Content-Type"] ||= 'application/pdf'
			  @action_view.controller.headers["Content-Disposition"] ||= 'attachment; filename="' + @rails_pdf_name + '"'
      
      	#pdf = ::PDF::Writer.new( :paper => PAPER )
      	pdf = PDF::Writer.new( :paper => PAPER )
      	pdf.compressed = true if RAILS_ENV != 'development'
		    eval template, nil, "#{@action_view.base_path}/#{@action_view.first_render}.#{@action_view.pick_template_extension(@action_view.first_render)}" 

      	pdf.render
    	end
  	end
end