require "rails_helper"

RSpec.shared_examples "closure outcomes spec" do |klass|
  describe klass, type: :controller do
    let(:manager) { find_or_create :disclosure_bmt_user }
    # let(:responded_case) { create :responded_case }

    describe "#closure_outcomes" do
      before do
        sign_in manager
      end

      it "is the correct controller" do
        expect(controller).to be_a(klass)
      end

      it "authorises" do
        expect {
          get :closure_outcomes, params: { id: kase.id }
        }.to require_permission(:can_close_case?)
          .with_args(manager, kase)
      end

      it "renders closure_outcomes.html.slim" do
        get :closure_outcomes, params: { id: kase.id }
        expect(response).to render_template(:closure_outcomes)
      end
    end
  end
end
