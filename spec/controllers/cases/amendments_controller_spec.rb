require "rails_helper"

RSpec.describe Cases::AmendmentsController, type: :controller do
  let(:private_officer) { find_or_create :private_officer }
  let(:pending_private_clearance_case) do
    create(
      :pending_private_clearance_case,
      private_officer:,
    )
  end

  describe "#new" do
    before do
      sign_in private_officer
    end

    it "authorizes" do
      expect {
        get :new, params: { case_id: pending_private_clearance_case.id }
      }.to require_permission(:execute_request_amends?).with_args(
        private_officer,
        pending_private_clearance_case,
      )
    end

    it "instantiates NextStepInfo object" do
      nsi = instance_double(NextStepInfo)
      allow(NextStepInfo).to receive(:new).with(any_args).and_return(nsi)

      get :new, params: { case_id: pending_private_clearance_case.id }

      expect(assigns(:next_step_info)).to eq nsi
      expect(NextStepInfo).to have_received(:new).with(
        pending_private_clearance_case,
        "request-amends",
        private_officer,
      )
    end

    it "renders the request_amends template" do
      get :new, params: { case_id: pending_private_clearance_case.id }
      expect(response).to have_rendered("new")
    end
  end

  describe "#create" do
    let(:service) { instance_double(CaseRequestAmendsService, call: true) }

    context "Full approval FOI" do
      before do
        sign_in private_officer
        allow(CaseRequestAmendsService).to receive(:new).and_return(service)
      end

      it "authorizes" do
        expect {
          post :create, params: {
            case_id: pending_private_clearance_case,
            case: {
              request_amends_comment: "Oh my!",
              draft_compliant: "no",
            },
          }
        }.to require_permission(:execute_request_amends?).with_args(
          private_officer,
          pending_private_clearance_case,
        )
      end

      it "calls the case request amends service" do
        post :create, params: {
          case_id: pending_private_clearance_case,
          case: {
            request_amends_comment: "Oh my!",
            draft_compliant: "no",
          },
        }

        expect(CaseRequestAmendsService)
          .to have_received(:new).with(
            user: private_officer,
            kase: pending_private_clearance_case,
            message: "Oh my!",
            is_compliant: false,
          )

        expect(service).to have_received(:call)
      end

      it "flashes a notification" do
        post :create, params: {
          case_id: pending_private_clearance_case,
          case: {
            request_amends_comment: "Oh my!",
            compliance: "no",
          },
        }

        expect(flash[:notice])
          .to eq "You have requested amends to this case's response."
      end

      it "redirects to case detail page" do
        post :create, params: {
          case_id: pending_private_clearance_case,
          case: {
            request_amends_comment: "Oh my!",
            compliance: "no",
          },
        }

        expect(response).to redirect_to(case_path(pending_private_clearance_case))
      end
    end

    context "trigger SAR" do
      let(:trigger_sar) do
        (create :pending_dacu_clearance_sar, approver: disclosure_specialist).decorate
      end

      let(:disclosure_specialist) { find_or_create :disclosure_specialist }

      before do
        sign_in disclosure_specialist
        allow(CaseRequestAmendsService).to receive(:new).and_return(service)
      end

      it "calls the case request amends service with disclosure specialist" do
        post :create, params: {
          case_id: trigger_sar,
          case: {
            request_amends_comment: "Sneaky puppies",
            draft_compliant: "yes",
          },
        }

        expect(CaseRequestAmendsService)
          .to have_received(:new).with(
            user: disclosure_specialist,
            kase: trigger_sar,
            message: "Sneaky puppies",
            is_compliant: true,
          )

        expect(service).to have_received(:call)
      end

      it "flashes a notification for SARs" do
        post :create, params: {
          case_id: trigger_sar,
          case: {
            request_amends_comment: "Sneaky puppies",
            compliance: "no",
          },
        }

        expect(flash[:notice])
          .to eq "Information Officer has been notified a redraft is needed."
      end
    end
  end
end
