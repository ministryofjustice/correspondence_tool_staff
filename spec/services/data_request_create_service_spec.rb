require "rails_helper"

class FakeError < ArgumentError; end

describe DataRequestCreateService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area }
  let(:data_request_attributes) do
    {
      location: "The Clinic",
      request_type: "all_prison_records",
      request_type_note: "Lorem ipsum",
      date_requested_dd: "15",
      date_requested_mm: "8",
      date_requested_yyyy: "2020",
      date_from_dd: "15",
      date_from_mm: "8",
      date_from_yyyy: "2018",
      date_to_dd: "15",
      date_to_mm: "8",
      date_to_yyyy: "2019",
    }
  end
  let(:service) do
    described_class.new(
      kase: offender_sar_case,
      user:,
      data_request_area:,
      data_request_params: data_request_attributes,
    )
  end

  describe "#initialize" do
    it "requires a case and user" do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.instance_variable_get(:@data_request_area)).to eq data_request_area
    end

    # No restriction on case type as managed by model
    it "ignores case type" do
      new_service = described_class.new(
        kase: create(:foi_case),
        user:,
        data_request_area:,
        data_request_params: data_request_attributes,
      )

      expect(new_service).to be_instance_of described_class
    end
  end

  describe "#call" do
    context "when on success" do
      it "saves DataRequest and changes case status" do
        expect(offender_sar_case.current_state).to eq "data_to_be_requested"
        expect { service.call }.to change(DataRequest.all, :size).by(1)
        expect(offender_sar_case.current_state).to eq "waiting_for_data"

        # @todo CaseTransition Added

        expect(service.result).to eq :ok
      end

      it "creates a data request with the attributes given" do
        service.call
        expect(service.data_request).to be_persisted
        expect(service.data_request.location).to eq "The Clinic"
        expect(service.data_request.request_type).to eq "all_prison_records"
        expect(service.data_request.request_type_note).to eq "Lorem ipsum"
        expect(service.data_request.date_from).to eq Date.new(2018, 8, 15)
        expect(service.data_request.date_to).to eq Date.new(2019, 8, 15)
      end
    end

    context "when on failure" do
      it "does not save DataRequest when validation errors" do
        params = data_request_attributes.clone
        params.merge!({ request_type: "" })

        service = described_class.new(
          kase: offender_sar_case,
          user:,
          data_request_area:,
          data_request_params: params,
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.case.errors.size).to be > 0
        expect(service.result).to eq :error
      end

      it "does not save DataRequest when nothing to process" do
        service = described_class.new(
          kase: offender_sar_case,
          user:,
          data_request_area:,
          data_request_params: {},
        )

        expect { service.call }.to change(DataRequest.all, :size).by(0)
        expect(service.result).to eq :error
      end

      it "only recovers from ActiveRecord exceptions" do
        allow_any_instance_of(Case::Base).to receive(:save!).and_raise(FakeError) # rubocop:disable RSpec/AnyInstance
        expect { service.call }.to raise_error FakeError
      end
    end
  end
end
