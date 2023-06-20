require "rails_helper"

describe Cases::SarExtensionsController, type: :controller do
  let(:manager)           { find_or_create :disclosure_bmt_user }
  let(:extended_sar_case) { create :approved_sar, :extended_deadline_sar }
  let(:sar_case)          { create :sar_case }
  let(:approved_sar)      { create :approved_sar }

  let(:service) do
    double(CaseExtendSARDeadlineService, call: :ok, result: :ok)
  end

  let(:post_params) do
    {
      case_id: approved_sar.id,
      case: {
        extension_period: "11",
        reason_for_extending: "need more time",
      },
    }
  end

  before do
    sign_in manager
  end

  describe "#new" do
    it "authorizes" do
      expect {
        get :new, params: {
          case_id: sar_case.id,
        }
      }.to require_permission(:extend_sar_deadline?).with_args(manager, sar_case)
      expect(assigns(:case)).to be_a CaseExtendSARDeadlineDecorator
    end
  end

  describe "#create" do
    before do
      allow(CaseExtendSARDeadlineService).to receive(:new).and_return(service)
      sign_in manager
    end

    it "authorizes" do
      expect { post :create, params: post_params }
        .to require_permission(:extend_sar_deadline?).with_args(manager, approved_sar)
    end

    context "with valid params" do
      before do
        post :create, params: post_params
      end

      it "calls the CaseExtendSARDeadlineService" do
        expect(CaseExtendSARDeadlineService).to(
          have_received(:new)
            .with(
              user: manager,
              kase: approved_sar,
              extension_period: "11",
              reason: "need more time",
            ),
        )

        expect(service).to have_received(:call)
      end

      it "notifies the user of the success" do
        expect(request.flash[:notice]).to eq "Case extended for SAR"
      end
    end

    context "with invalid params" do
      let(:service) do
        double(
          CaseExtendSARDeadlineService,
          call: :validation_error,
          result: :validation_error,
        )
      end

      it "renders the new page" do
        post :create, params: post_params
        expect(:result).to have_rendered(:new)
      end
    end

    context "when failed request" do
      let(:service) do
        double(
          CaseExtendSARDeadlineService,
          call: :error,
          result: :error,
        )
      end

      it "notifies the user of the failure" do
        post :create, params: post_params
        expected_message = "Unable to perform SAR extension on case #{approved_sar.number}"

        expect(request.flash[:alert]).to eq expected_message
        expect(:result).to redirect_to(case_path(approved_sar.id))
      end
    end
  end

  describe "#destroy" do
    it "authorizes" do
      expect {
        delete :destroy,
               params: {
                 case_id: extended_sar_case.id,
               }
      }.to require_permission(:remove_sar_deadline_extension?).with_args(
        manager,
        extended_sar_case,
      )
    end
  end
end
