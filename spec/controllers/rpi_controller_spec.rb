require "rails_helper"

RSpec.describe RpiController, type: :controller do
  let(:user) { create(:user) }
  let(:submission_id) { "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3" }
  let!(:rpi) { create(:personal_information_request, submission_id:) }

  let(:presigned_url) { "http://pre-signed.com/url" }
  let(:object) { instance_double(Aws::S3::Object, presigned_url:) }

  before do
    allow(CASE_UPLOADS_S3_BUCKET).to receive(:object).with(rpi.key).and_return(object)
  end

  describe "GET #download" do
    before do
      sign_in user
    end

    it "stores current user and time of download" do
      expect(rpi.last_accessed_at).to be_nil

      get :download, params: { id: submission_id }
      rpi.reload

      expect(rpi.last_accessed_at).not_to be_nil
      expect(rpi.last_accessed_by).to eq user.id
    end

    it "redirects to the zipfile's url" do
      get :download, params: { id: submission_id }
      expect(response).to redirect_to presigned_url
    end
  end
end
