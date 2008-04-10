require File.dirname(__FILE__) + '/../test_helper'
require 'cart_items_controller'

# Re-raise errors caught by the controller.
class CartItemsController; def rescue_action(e) raise e end; end

class CartItemsControllerTest < Test::Unit::TestCase
  def setup
    @controller = CartItemsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
