require "rails_helper"

describe CasesController, type: :controller do
  describe "GET destroy_case" do
    let(:manager)           { create :manager }
    let(:params)            { { id: kase.id, case: { reason_for_deletion: "I was told to" } } }

    before { sign_in manager }

    context "when FOI case" do
      let(:kase) { create :foi_case }

      it "authorises" do
        expect {
          delete :destroy, params:
        }.to require_permission(:destroy?)
                 .with_args(manager, kase)
      end

      it "sets @case" do
        delete(:destroy, params:)
        expect(assigns(:case)).to eq kase
      end

      it "marks the case as deleted" do
        delete(:destroy, params:)
        kase.reload
        expect(kase.deleted?).to be true
      end
    end

    context "when SAR case" do
      let(:kase) { create :sar_case }

      it "marks a SAR case as deleted" do
        delete(:destroy, params:)
        kase.reload
        expect(kase.deleted?).to be true
      end
    end

    context "when ICO FOI case" do
      let(:kase)   { create :ico_foi_case }

      it "marks an ICO FOI case as deleted" do
        delete(:destroy, params:)
        kase.reload
        expect(kase.deleted?).to be true
      end
    end

    context "when ICO SAR case" do
      let(:kase)   { create :ico_sar_case }

      it "marks an ICO SAR case as deleted" do
        delete(:destroy, params:)
        kase.reload
        expect(kase.deleted?).to be true
      end
    end
  end
end
