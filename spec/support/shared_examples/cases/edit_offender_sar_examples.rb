require "rails_helper"

RSpec.shared_examples "edit offender sar spec" do |current_state, event_name|
  def offender_sar_case(with_trait:)
    create :offender_sar_case, with_trait.to_sym
  end

  let(:manager) { find_or_create :branston_user }
  let(:offender_sar) { (offender_sar_case with_trait: current_state).decorate }
  let(:params) { { id: offender_sar.id, transition_name: event_name } }

  before do
    sign_in manager
  end

  describe "#transition" do
    it "authorizes" do
      expect { patch :transition, params: }
        .to require_permission("transition?").with_args(manager, offender_sar)
    end

    context "when updates Offender SAR state" do
      before do
        patch :transition, params:
      end

      it "sets case" do
        expect(assigns(:case)).to eq offender_sar
      end

      it "flashes a notification" do
        expect(controller.flash[:notice]).to eq "Case updated"
      end

      it "redirects to case details page" do
        expect(response).to redirect_to(case_path(offender_sar))
      end

      it "changes case state" do
        expect(offender_sar.current_state).not_to eq current_state
      end
    end
  end
end
