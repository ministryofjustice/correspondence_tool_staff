require "rails_helper"

RSpec.describe Cases::DataRequestsController, type: :controller do
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

    it "builds @data_request" do
      data_request = assigns(:data_request)
      expect(data_request).to be_a DataRequest
    end
  end

  describe "#create" do
    context "with valid params" do
      let(:params) do
        {
          data_request: {
            location: "Wormwood Scrubs",
            request_type: "all_prison_records",
            date_requested_dd: "15",
            date_requested_mm: "8",
            date_requested_yyyy: "2020",
          },
          case_id: offender_sar_case.id,
        }
      end

      it "creates a new DataRequest" do
        expect { post(:create, params:) }
          .to change(DataRequest.all, :size).by 1
        expect(response).to redirect_to case_path(offender_sar_case)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          data_request: {
            location: "",
            request_type: "all_prison_records",
            date_requested_dd: "15",
            date_requested_mm: "8",
            date_requested_yyyy: "2020",
          },
          case_id: offender_sar_case.id,
        }
      end

      it "does not create a new DataRequest" do
        expect { post :create, params: invalid_params }
          .to change(DataRequest.all, :size).by 0
        expect(response).to render_template(:new)
      end
    end
  end

  describe "#show" do
    let(:data_request) do
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Time.zone.yesterday,
      )
    end

    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    end

    it "loads the correct data_request" do
      get(:show, params:)

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Time.zone.yesterday
    end
  end

  describe "#edit" do
    let(:data_request) do
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Time.zone.yesterday,
      )
    end

    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    end

    it "builds a new data_request with last received values" do
      get(:edit, params:)

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Time.zone.yesterday
    end
  end

  describe "#update" do
    let(:data_request) do
      create(:data_request, offender_sar_case:)
    end

    context "with valid params" do
      let(:params) do
        {
          data_request: {
            cached_num_pages: 2,
            location: "HMP Brixton",
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      end

      before do
        patch :update, params:
      end

      it "updates the DataRequest" do
        expect(response).to redirect_to case_path(data_request.case_id)
        expect(controller).to set_flash[:notice]
      end

      it "permits num_pages to be updated" do
        expect(controller.send(:update_params).key?(:cached_num_pages)).to be true
      end
    end

    context "with invalid params" do
      let(:params) do
        {
          data_request: {
            id: data_request.id,
            cached_num_pages: -10,
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      end

      it "does not update the DataRequest" do
        patch(:update, params:)
        expect(response).to render_template(:edit)
      end
    end

    context "with unknown service result" do
      let(:params) do
        {
          data_request: {
            id: data_request.id,
            date_received_dd: 2,
            date_received_mm: 8,
            date_received_yyyy: 2012,
            num_pages: 2,
          },
          id: data_request.id,
          case_id: data_request.case_id,
        }
      end

      it "raises an ArgumentError" do
        allow_any_instance_of(DataRequestUpdateService) # rubocop:disable RSpec/AnyInstance
          .to receive(:result).and_return(:bogus_result!)

        expect { patch :update, params: }
          .to raise_error ArgumentError, match(/Unknown result/)
      end
    end
  end

  describe "#destroy" do
    it "is not implemented" do
      data_request = create(:data_request, offender_sar_case:)

      expect { delete :destroy, params: { case_id: offender_sar_case.id, id: data_request.id } }
        .to raise_error NotImplementedError, "Data request delete unavailable"
    end
  end

  describe "#send_email" do
    let(:data_request) do
      create(
        :data_request,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Time.zone.yesterday,
        commissioning_document:,
      )
    end
    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
      }
    end
    let(:commissioning_document) { create(:commissioning_document, template_name:) }
    let(:template_name) { "prison" }

    it "assigns value to recipient emails" do
      allow_any_instance_of(DataRequest) # rubocop:disable RSpec/AnyInstance
        .to receive(:recipient_emails).and_return("test@email.com")
      get(:send_email, params:)
      expect(assigns(:recipient_emails)).to eq("test@email.com")
    end

    context "with no associated email" do
      it "returns no associated email present" do
        allow_any_instance_of(DataRequest) # rubocop:disable RSpec/AnyInstance
          .to receive(:recipient_emails).and_return([])
        get(:send_email, params:)
        expect(assigns(:no_email_present)).to eq(true)
      end
    end

    context "when probation document selected" do
      let(:template_name) { "probation" }

      it "routes to the send_email branston probation page" do
        get(:send_email, params:)
        expect(response).to render_template(:probation_send_email)
      end

      context "with confirm probation email" do
        let(:params) do
          {
            id: data_request.id,
            case_id: data_request.case_id,
            probation_commissioning_document_email: {
              probation: 1,
              email_branston_archives: "yes",
            },
          }
        end

        it "adds the branston probation email to recipients" do
          post(:send_email, params:)
          expect(response).to render_template(:send_email)
          expect(assigns(:recipient_emails)).to include(CommissioningDocumentTemplate::Probation::BRANSTON_ARCHIVES_EMAIL)
        end
      end

      context "with decline probation email" do
        let(:params) do
          {
            id: data_request.id,
            case_id: data_request.case_id,
            probation_commissioning_document_email: {
              probation: 1,
              email_branston_archives: "no",
            },
          }
        end

        it "doesnt add the branston probation email to recipients" do
          post(:send_email, params:)
          expect(response).to render_template(:send_email)
          expect(assigns(:recipient_emails)).not_to include(CommissioningDocumentTemplate::Probation::BRANSTON_ARCHIVES_EMAIL)
        end
      end

      context "with no options chosen" do
        let(:params) do
          {
            id: data_request.id,
            case_id: data_request.case_id,
            probation_commissioning_document_email: {
              probation: 1,
            },
          }
        end

        it "raises error message" do
          post(:send_email, params:)
          expect(response).to render_template(:probation_send_email)
          expect(assigns(:email)).not_to be_valid
        end
      end
    end

    context "with non-probation document" do
      let(:template_name) { "prison" }

      it "routes to the send_email confirmation page" do
        get(:send_email, params:)
        expect(response).to render_template(:send_email)
      end
    end
  end
end
