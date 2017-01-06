require 'test_helper'

class JrsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @jr = jrs(:one)
  end

  test "should get index" do
    get jrs_url
    assert_response :success
  end

  test "should get new" do
    get new_jr_url
    assert_response :success
  end

  test "should create jr" do
    assert_difference('Jr.count') do
      post jrs_url, params: { jr: { classname: @jr.classname, description: @jr.description, name: @jr.name, platform: @jr.platform, url: @jr.url, version: @jr.version } }
    end

    assert_redirected_to jr_url(Jr.last)
  end

  test "should show jr" do
    get jr_url(@jr)
    assert_response :success
  end

  test "should get edit" do
    get edit_jr_url(@jr)
    assert_response :success
  end

  test "should update jr" do
    patch jr_url(@jr), params: { jr: { classname: @jr.classname, description: @jr.description, name: @jr.name, platform: @jr.platform, url: @jr.url, version: @jr.version } }
    assert_redirected_to jr_url(@jr)
  end

  test "should destroy jr" do
    assert_difference('Jr.count', -1) do
      delete jr_url(@jr)
    end

    assert_redirected_to jrs_url
  end
end
