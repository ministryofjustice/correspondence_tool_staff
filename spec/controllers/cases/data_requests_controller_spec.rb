require "rails_helper"

RSpec.describe Cases::DataRequestsController, type: :controller do
  let(:manager) { find_or_create :branston_user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area, data_request_area_type: "prison", offender_sar_case: }

  before do
    sign_in manager
  end

  describe "#new" do
    before do
      get :new, params: { case_id: offender_sar_case.id, data_request_area_id: data_request_area.id }
    end

    it "sets @case" do
      expect(assigns(:case)).to eq offender_sar_case
    end

    it "builds @data_request" do
      data_request = assigns(:data_request)
      expect(data_request).to be_a DataRequest
    end

    it "assigns the correct data_request_area to @data_request" do
      data_request = assigns(:data_request)
      expect(data_request.data_request_area).to eq(data_request_area)
    end

    it "assigns the correct data_request_types for the form" do
      data_request = assigns(:data_request)
      expect(data_request.data_request_types).to eq(DataRequest::PRISON_DATA_REQUEST_TYPES)
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
          data_request_area_id: data_request_area.id,
        }
      end

      it "creates a new DataRequest" do
        expect { post(:create, params:) }
          .to change(DataRequest.all, :size).by 1
        expect(response).to redirect_to case_data_request_area_path(offender_sar_case, data_request_area)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          data_request: {
            request_type: "",
            date_requested_dd: "15",
            date_requested_mm: "8",
            date_requested_yyyy: "2020",
          },
          case_id: offender_sar_case.id,
          data_request_area_id: data_request_area.id,
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
        data_request_area:,
        offender_sar_case:,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Time.zone.yesterday,
      )
    end

    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
        data_request_area_id: data_request.data_request_area_id,
      }
    end

    it "loads the correct data_request" do
      get(:show, params:)

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Time.zone.yesterday
    end

    context "when closed case" do
      let(:offender_sar_case) { create :offender_sar_case, :closed }
      let(:data_request) do
        create(
          :data_request,
          data_request_area:,
          offender_sar_case:,
          cached_num_pages: 10,
          completed: true,
          cached_date_received: Time.zone.yesterday,
        )
      end

      it "allows access" do
        get(:show, params:)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "#edit" do
    let(:data_request) do
      create(
        :data_request,
        data_request_area:,
        offender_sar_case:,
        cached_num_pages: 10,
        completed: true,
        cached_date_received: Time.zone.yesterday,
      )
    end

    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
        data_request_area_id: data_request_area.id,
      }
    end

    it "builds a new data_request with last received values" do
      get(:edit, params:)

      expect(assigns(:data_request)).to be_a DataRequest
      expect(assigns(:data_request).cached_num_pages).to eq 10
      expect(assigns(:data_request).cached_date_received).to eq Time.zone.yesterday
    end

    context "when closed case" do
      let(:offender_sar_case) { create :offender_sar_case, :closed }
      let(:data_request) do
        create(
          :data_request,
          data_request_area:,
          offender_sar_case:,
          cached_num_pages: 10,
          completed: true,
          cached_date_received: Time.zone.yesterday,
        )
      end

      it "does not authorise access" do
        get(:edit, params:)
        expect(flash[:alert]).to eq "You cannot edit data request once the case has been closed."
      end
    end
  end

  describe "#update" do
    let(:data_request) do
      create(
        :data_request,
        data_request_area:,
        offender_sar_case:,
      )
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
          data_request_area_id: data_request_area.id,
        }
      end

      before do
        patch :update, params:
      end

      it "updates the DataRequest" do
        expect(response).to redirect_to case_data_request_area_path(offender_sar_case, data_request_area)
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
          data_request_area_id: data_request_area.id,
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
          data_request_area_id: data_request_area.id,
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
    let(:data_request) do
      create(
        :data_request,
        data_request_area:,
        offender_sar_case:,
      )
    end

    let(:params) do
      {
        id: data_request.id,
        case_id: data_request.case_id,
        data_request_area_id: data_request_area.id,
      }
    end

    it "is not implemented" do
      expect { delete :destroy, params: { case_id: offender_sar_case.id, data_request_area_id: data_request_area.id, id: data_request.id } }
        .to raise_error NotImplementedError, "Data request delete unavailable"
    end
  end
end
