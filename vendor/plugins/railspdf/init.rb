# Include hook code here
require "railspdf"
#require "ActionView"

ActionView::Base.register_template_handler 'rpdf', RailsPDF::PDFRender