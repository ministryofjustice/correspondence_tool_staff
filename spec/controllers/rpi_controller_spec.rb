require "rails_helper"

RSpec.describe RpiController, type: :controller do
  let(:user) { create(:user) }
  let(:submission_id) { "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3" }
  let!(:rpi) { create(:personal_information_request, submission_id:) }

  let(:presigned_url) { "http://pre-signed.com/url" }
  let(:object) { instance_double(Aws::S3::Object, presigned_url:) }

  before do
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                     .with(rpi.key)
                                     .and_return(object)
  end

  describe "GET #show" do
    before do
      sign_in user
    end

    it "redirects to the zipfile's url" do
      get :show, params: { id: submission_id }
      expect(response).to redirect_to presigned_url
    end
  end
end
