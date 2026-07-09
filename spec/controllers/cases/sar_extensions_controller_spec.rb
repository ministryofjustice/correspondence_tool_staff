require "rails_helper"

describe Cases::SARExtensionsController, type: :controller do
  let(:manager)           { find_or_create :disclosure_bmt_user }
  let(:extended_sar_case) { create :approved_sar, :extended_deadline_sar }
  let(:sar_case)          { create :sar_case }
  let(:approved_sar)      { create :approved_sar }

  let(:service) do
    instance_double(CaseExtendSARDeadlineService, call: :ok, result: :ok)
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
        expect(request.flash[:notice]).to eq "The deadline has been extended by 2 months."
      end
    end

    context "with invalid params" do
      let(:service) do
        instance_double(
          CaseExtendSARDeadlineService,
          call: :validation_error,
          result: :validation_error,
        )
      end

      it "renders the new page" do
        post :create, params: post_params
        expect(request).to have_rendered(:new)
      end
    end

    context "when failed request" do
      let(:service) do
        instance_double(
          CaseExtendSARDeadlineService,
          call: :error,
          result: :error,
        )
      end

      it "notifies the user of the failure" do
        post :create, params: post_params
        expected_message = "Unable to perform SAR extension on case #{approved_sar.number}"

        expect(request.flash[:alert]).to eq expected_message
        expect(request).to redirect_to(case_path(approved_sar.id))
      end
    end
  end

  describe "#edit" do
    it "authorizes" do
      expect {
        get :edit, params: {
          case_id: extended_sar_case.id,
        }
      }.to require_permission(:remove_sar_deadline_extension?).with_args(manager, extended_sar_case)
      expect(assigns(:case)).to be_a CaseRemoveSARDeadlineExtensionDecorator
    end
  end

  describe "#destroy" do
    let(:remove_service) do
      instance_double(CaseRemoveSARDeadlineExtensionService, call: :ok, result: :ok)
    end

    let(:delete_params) do
      {
        case_id: extended_sar_case.id,
        case: {
          reason_for_removing_extension: "no longer needed",
        },
      }
    end

    before do
      allow(CaseRemoveSARDeadlineExtensionService).to receive(:new).and_return(remove_service)
    end

    it "authorizes" do
      expect { delete :destroy, params: delete_params }
        .to require_permission(:remove_sar_deadline_extension?).with_args(manager, extended_sar_case)
    end

    context "with valid params" do
      before do
        delete :destroy, params: delete_params
      end

      it "calls the CaseRemoveSARDeadlineExtensionService" do
        expect(CaseRemoveSARDeadlineExtensionService).to(
          have_received(:new).with(
            manager,
            extended_sar_case,
            reason: "no longer needed",
          ),
        )

        expect(remove_service).to have_received(:call)
      end

      it "notifies the user of the success" do
        expect(request.flash[:notice]).to eq "The deadline extension has been removed."
      end
    end

    context "with invalid params" do
      let(:remove_service) do
        instance_double(
          CaseRemoveSARDeadlineExtensionService,
          call: :validation_error,
          result: :validation_error,
        )
      end

      it "renders the edit page" do
        delete :destroy, params: delete_params
        expect(request).to have_rendered(:edit)
      end
    end

    context "when failed request" do
      let(:remove_service) do
        instance_double(
          CaseRemoveSARDeadlineExtensionService,
          call: :error,
          result: :error,
        )
      end

      it "notifies the user of the failure" do
        delete :destroy, params: delete_params
        expect(request.flash[:alert]).to eq "Unable to remove SAR deadline extension"
        expect(request).to redirect_to(case_path(extended_sar_case.id))
      end
    end
  end
end
