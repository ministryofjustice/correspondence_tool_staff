require "rails_helper"

RSpec.describe Cases::CoverPagesController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }

  before do
    sign_in manager
  end

  describe "#show" do
    before do
      get :show, params: { case_id: offender_sar_case.id }
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end
  end
end
