require 'test_helper'

class DialJobsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dial_jobs)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dial_job" do
    assert_difference('DialJob.count') do
      post :create, :dial_job => { }
    end

    assert_redirected_to dial_job_path(assigns(:dial_job))
  end

  test "should show dial_job" do
    get :show, :id => dial_jobs(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => dial_jobs(:one).id
    assert_response :success
  end

  test "should update dial_job" do
    put :update, :id => dial_jobs(:one).id, :dial_job => { }
    assert_redirected_to dial_job_path(assigns(:dial_job))
  end

  test "should destroy dial_job" do
    assert_difference('DialJob.count', -1) do
      delete :destroy, :id => dial_jobs(:one).id
    end

    assert_redirected_to dial_jobs_path
  end
end
