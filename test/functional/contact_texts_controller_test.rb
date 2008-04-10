require File.dirname(__FILE__) + '/../test_helper'
require 'contact_texts_controller'

# Re-raise errors caught by the controller.
class ContactTextsController; def rescue_action(e) raise e end; end

class ContactTextsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ContactTextsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
