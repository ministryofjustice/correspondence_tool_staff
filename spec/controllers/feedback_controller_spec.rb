require "rails_helper"

RSpec.describe FeedbackController, type: :controller do
  let(:user) { create(:user) }
  let(:params) do
    {
      feedback: {
        comment: "This is my feedback",
      },
    }
  end

  describe "#create" do
    context "when an anonymous user" do
      it "redirect to signin if trying to submit new feedback" do
        post(:create, params:)
        expect(response).to redirect_to(new_user_session_path)
      end

      it "return 401 if trying to submit new feedback using AJAX" do
        post :create, params:, xhr: true
        expect(response.code).to eq "401"
      end
    end

    context "when an authenticated user" do
      before do
        sign_in user
        post :create, params:, xhr: true
      end

      it "return 200 if using AJAX" do
        expect(response.code).to eq "200"
      end

      it "makes a DB entry" do
        expect(Feedback.first.comment).to eq "This is my feedback"
        expect(Feedback.first.email).to eq user.email
      end
    end
  end
end
