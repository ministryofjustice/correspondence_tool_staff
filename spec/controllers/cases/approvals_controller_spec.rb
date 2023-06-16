require "rails_helper"

RSpec.describe Cases::ApprovalsController, type: :controller do
  let(:responded_trigger_case) { create :pending_dacu_clearance_case }
  let(:approver) { responded_trigger_case.approvers.first }
  let(:params) { { case_id: responded_trigger_case } }

  let(:service) do
    instance_double(
      CaseApprovalService,
      call: true,
      result: :ok,
    )
  end

  describe "#new" do
    before do
      sign_in approver
    end

    it "authorizes" do
      expect { get :new, params: }
        .to require_permission(:approve?)
          .with_args(approver, responded_trigger_case)
    end

    it "renders the approve page" do
      get(:new, params:)
      expect(response).to have_rendered("new")
    end
  end

  describe "#create" do
    before do
      sign_in approver
      allow(CaseApprovalService).to receive(:new).and_return(service)
    end

    it "authorizes" do
      expect { post :create, params: }
        .to require_permission(:approve?).with_args(
          approver,
          responded_trigger_case,
        )
    end

    it "calls the case approval service" do
      post(:create, params:)

      expect(CaseApprovalService).to have_received(:new).with(
        hash_including(user: approver, kase: responded_trigger_case),
      )
      expect(service).to have_received(:call)
    end

    it "flashes a notification" do
      post(:create, params:)
      expect(flash[:notice])
        .to eq "Disclosure has been notified that the response is pending clearance."
    end

    it "redirects to case detail page" do
      post(:create, params:)
      expect(response).to redirect_to(case_path(responded_trigger_case))
    end
  end
end
