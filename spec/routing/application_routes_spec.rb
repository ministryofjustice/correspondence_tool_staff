require "rails_helper"

describe "application routes", type: :routing do
  let(:manager)   { create :manager }
  let(:responder) { find_or_create :foi_responder }
  let(:approver)  { create :approver }

  describe "/ redirects", type: :request do
    before do
      login_as user
      get "/"
    end

    context "manager user" do
      let(:user) { manager }

      it { is_expected.to redirect_to "/cases/open" }
    end

    context "responder user" do
      let(:user) { responder }

      it { is_expected.to redirect_to "/cases/open" }
    end

    context "approver user" do
      let(:user) { approver }

      it { is_expected.to redirect_to "/cases/open" }
    end
  end
end
