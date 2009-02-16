require 'test_helper'

class CampaignUserRolesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:campaign_user_roles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create campaign_user_role" do
    assert_difference('CampaignUserRole.count') do
      post :create, :campaign_user_role => { }
    end

    assert_redirected_to campaign_user_role_path(assigns(:campaign_user_role))
  end

  test "should show campaign_user_role" do
    get :show, :id => campaign_user_roles(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => campaign_user_roles(:one).id
    assert_response :success
  end

  test "should update campaign_user_role" do
    put :update, :id => campaign_user_roles(:one).id, :campaign_user_role => { }
    assert_redirected_to campaign_user_role_path(assigns(:campaign_user_role))
  end

  test "should destroy campaign_user_role" do
    assert_difference('CampaignUserRole.count', -1) do
      delete :destroy, :id => campaign_user_roles(:one).id
    end

    assert_redirected_to campaign_user_roles_path
  end
end
