require File.dirname(__FILE__) + '/../test_helper'
require 'volunteer_tasks_controller'

# Re-raise errors caught by the controller.
class VolunteerTasksController; def rescue_action(e) raise e end; end

class VolunteerTasksControllerTest < Test::Unit::TestCase
  fixtures :volunteer_tasks

  def setup
    @controller = VolunteerTasksController.new
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

    assert_not_nil assigns(:volunteer_tasks)
  end

  def test_show
    get :show, :id => 1

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:volunteer_task)
    assert assigns(:volunteer_task).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:volunteer_task)
  end

  def test_create
    num_volunteer_tasks = VolunteerTask.count

    post :create, :volunteer_task => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_volunteer_tasks + 1, VolunteerTask.count
  end

  def test_edit
    get :edit, :id => 1

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:volunteer_task)
    assert assigns(:volunteer_task).valid?
  end

  def test_update
    post :update, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => 1
  end

  def test_destroy
    assert_not_nil VolunteerTask.find(1)

    post :destroy, :id => 1
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      VolunteerTask.find(1)
    }
  end
end
