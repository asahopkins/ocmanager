require File.dirname(__FILE__) + '/../test_helper'
require 'group_memberships_controller'

# Re-raise errors caught by the controller.
class GroupMembershipsController; def rescue_action(e) raise e end; end

class GroupMembershipsControllerTest < Test::Unit::TestCase
  def setup
    @controller = GroupMembershipsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
