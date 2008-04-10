require File.dirname(__FILE__) + '/../test_helper'
require 'backend_controller'

class BackendController; def rescue_action(e) raise e end; end

class BackendControllerApiTest < Test::Unit::TestCase
  def setup
    @controller = BackendController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_find_entity_by_id
    result = invoke :find_entity_by_id
    assert_equal nil, result
  end

  def test_find_entity_by_name
    result = invoke :find_entity_by_name
    assert_equal nil, result
  end
end
