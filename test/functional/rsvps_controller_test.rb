require File.dirname(__FILE__) + '/../test_helper'
require 'rsvps_controller'

# Re-raise errors caught by the controller.
class RsvpsController; def rescue_action(e) raise e end; end

class RsvpsControllerTest < Test::Unit::TestCase
  def setup
    @controller = RsvpsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
