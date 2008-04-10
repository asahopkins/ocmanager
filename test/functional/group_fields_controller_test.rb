require File.dirname(__FILE__) + '/../test_helper'
require 'group_fields_controller'

# Re-raise errors caught by the controller.
class GroupFieldsController; def rescue_action(e) raise e end; end

class GroupFieldsControllerTest < Test::Unit::TestCase
  fixtures :group_fields

  def setup
    @controller = GroupFieldsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:group_fields)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:group_field)
    assert assigns(:group_field).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:group_field)
  end

  def test_create
    num_group_fields = GroupField.count

    post :create, :group_field => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_group_fields + 1, GroupField.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:group_field)
    assert assigns(:group_field).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil GroupField.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      GroupField.find(1)
    }
  end
end
