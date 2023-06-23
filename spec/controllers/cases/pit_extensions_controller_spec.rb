require "rails_helper"

describe Cases::PitExtensionsController, type: :controller do
  let(:manager) { find_or_create :disclosure_bmt_user }

  let(:case_being_drafted) do
    create :case_being_drafted, :flagged_accepted
  end

  let(:post_params) do
    {
      case_id: case_being_drafted.id,
      case: {
        extension_deadline_yyyy: "2017",
        extension_deadline_mm: "02",
        extension_deadline_dd: "10",
        reason_for_extending: "need more time",
      },
    }
  end

  let(:service) { double(CaseExtendForPITService, call: :ok) }

  describe "#new" do
    before do
      sign_in manager
    end

    it "authorizes" do
      expect { get :new, params: { case_id: case_being_drafted.id } }
        .to require_permission(:extend_for_pit?).with_args(
          manager,
          case_being_drafted,
        )
    end

    it "assigns case object" do
      get :new, params: { case_id: case_being_drafted.id }

      expect(assigns(:case)).to be_a CaseExtendForPITDecorator
      expect(assigns(:case).object).to eq case_being_drafted
    end
  end

  describe "#create" do
    before do
      allow(CaseExtendForPITService).to receive(:new).and_return(service)
      sign_in manager
    end

    it "authorizes" do
      expect { post :create, params: post_params }
        .to require_permission(:extend_for_pit?).with_args(
          manager,
          case_being_drafted,
        )
    end

    context "with valid params" do
      before do
        post :create, params: post_params
      end

      it "calls the CaseExtendForPitService" do
        expect(CaseExtendForPITService)
          .to have_received(:new).with(
            manager,
            case_being_drafted,
            Date.new(2017, 2, 10),
            "need more time",
          )
        expect(service).to have_received(:call)
      end

      it "notifies the user of the success" do
        expect(request.flash[:notice]).to eq "Case extended for Public Interest Test (PIT)"
      end

      it "redirects to case details" do
        expect(request).to redirect_to(case_path(case_being_drafted.id))
      end
    end

    context "when on service error" do
      let(:service) { double(CaseExtendForPITService, call: :error) }

      before do
        post :create, params: post_params
      end

      it "notifies the user of the failure" do
        expect(flash[:alert]).to eq "Unable to perform PIT extension on case #{case_being_drafted.number}"
        expect(request).to redirect_to(case_path(case_being_drafted.id))
      end
    end
  end
end
