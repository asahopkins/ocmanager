# Include hook code here
require "railspdf"
#require "ActionView"

ActionView::Template.register_template_handler 'rpdf', RailsPDF::PDFRender