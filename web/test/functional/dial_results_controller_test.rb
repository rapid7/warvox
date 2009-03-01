require 'test_helper'

class DialResultsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dial_results)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dial_result" do
    assert_difference('DialResult.count') do
      post :create, :dial_result => { }
    end

    assert_redirected_to dial_result_path(assigns(:dial_result))
  end

  test "should show dial_result" do
    get :show, :id => dial_results(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => dial_results(:one).id
    assert_response :success
  end

  test "should update dial_result" do
    put :update, :id => dial_results(:one).id, :dial_result => { }
    assert_redirected_to dial_result_path(assigns(:dial_result))
  end

  test "should destroy dial_result" do
    assert_difference('DialResult.count', -1) do
      delete :destroy, :id => dial_results(:one).id
    end

    assert_redirected_to dial_results_path
  end
end
