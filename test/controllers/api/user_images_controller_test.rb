require 'test_helper'

describe Api::UserImagesController do
  let(:user_image) { create(:user_image) }

  it 'should show' do
    get(:show, api_request_opts(user_id: user_image.user_id))
    assert_response :success
  end
end
