require "rails_helper"

RSpec.describe Cases::DataRequestAreasController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }

  before do
    sign_in manager
  end

  describe "#new" do
    before do
      get :new, params: { case_id: offender_sar_case.id }
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it "builds @data_request_area" do
      data_request_area = assigns(:data_request_area)
      expect(data_request_area).to be_a DataRequestArea
    end
  end

  describe "#create" do
    context "with valid params" do
      let(:params) do
        {
          data_request_area: { data_request_area_type: "prison", location: "HMP" },
          case_id: offender_sar_case.id,
        }
      end

      it "creates a new DataRequestArea" do
        expect { post(:create, params:) }
          .to change(DataRequestArea.all, :size).by 1
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          data_request_area: { data_request_area_type: "", location: nil },
          case_id: offender_sar_case.id,
        }
      end

      it "does not create a new DataRequestArea" do
        expect { post :create, params: invalid_params }
          .to change(DataRequestArea.all, :size).by 0
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#show" do
    let(:data_request_area) { create :data_request_area, offender_sar_case: }

    let(:params) do
      {
        id: data_request_area.id,
        case_id: data_request_area.case_id,
      }
    end

    it "loads the correct data_request_area" do
      get(:show, params:)

      expect(assigns(:data_request_area)).to be_a DataRequestArea
      expect(assigns(:data_request_area).data_request_area_type).to eq "prison"
    end

    context "when closed case" do
      let(:data_request_area) do
        create(
          :data_request_area,
          offender_sar_case: create(:offender_sar_case, :closed),
        )
      end

      it "allows access" do
        get(:show, params:)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#destroy" do
    context "with a data request item" do
      let(:data_request_area) { create :data_request_area, offender_sar_case: }
      let!(:data_request) { create :data_request, data_request_area:, offender_sar_case: } # rubocop:disable RSpec/LetSetup
      let!(:data_request_email) { create(:data_request_email, data_request_area:) }

      it "is not destroyed" do
        expect {
          delete :destroy, params: { case_id: offender_sar_case.id, id: data_request_area.id }
        }.to change(DataRequestArea.all, :size).by(0)
        expect(flash[:notice]).to eq("Data request area cannot be destroyed because it has sent emails.")
        expect(response).to redirect_to case_path(offender_sar_case)
      end
    end

    context "with no data request item" do
      let!(:data_request_area) { create :data_request_area, offender_sar_case: }

      it "is destroyed" do
        expect {
          delete :destroy, params: { case_id: offender_sar_case.id, id: data_request_area.id }
        }.to change(DataRequestArea.all, :size).by(-1)
        expect(flash[:notice]).to eq("Data request was successfully destroyed.")
        expect(response).to redirect_to case_path(offender_sar_case)
      end
    end
  end

  describe "#send_email" do
    let(:data_request_area) do
      create(
        :data_request_area,
        offender_sar_case:,
        commissioning_document:,
      )
    end
    let(:params) do
      {
        case_id: data_request_area.case_id,
        id: data_request_area.id,
      }
    end
    let(:commissioning_document) { create(:commissioning_document, template_name:) }
    let(:template_name) { "standard" }

    it "assigns value to recipient emails" do
      allow_any_instance_of(DataRequestArea) # rubocop:disable RSpec/AnyInstance
        .to receive(:recipient_emails).and_return("test@email.com")
      get(:send_email, params:)
      expect(assigns(:recipient_emails)).to eq("test@email.com")
    end

    context "with no associated email" do
      it "returns no associated email present" do
        allow_any_instance_of(DataRequestArea) # rubocop:disable RSpec/AnyInstance
          .to receive(:recipient_emails).and_return([])
        get(:send_email, params:)
        expect(assigns(:no_email_present)).to eq(true)
      end
    end
  end
end
