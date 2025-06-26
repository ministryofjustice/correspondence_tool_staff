require "rails_helper"

class FakeError < ArgumentError; end

describe DataRequestUpdateService do
  let(:user) { create :user }
  let(:data_request) do
    create(
      :data_request,
      data_request_area:,
      request_type: "all_prison_records",
    )
  end
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area) { create :data_request_area, location: "HMP Brixton" }
  let(:params) do
    {
      request_type: "all_prison_records",
      request_type_note: "Lorem ipsum",
      date_from_dd: "15",
      date_from_mm: "8",
      date_from_yyyy: "2018",
      date_to_dd: "15",
      date_to_mm: "8",
      date_to_yyyy: "2019",
      cached_num_pages: 21,
    }
  end
  let(:service) do
    described_class.new(
      user:,
      data_request:,
      params:,
    )
  end

  describe "#initialize" do
    it "requires a user. data request and fields to update" do
      expect(service.instance_variable_get(:@user)).to eq user
      expect(service.data_request).to eq data_request
      expect(service.instance_variable_get(:@params)).to eq params
    end
  end

  describe "#call" do
    context "when a success" do
      let(:service) do
        described_class.new(
          user:,
          data_request:,
          params:,
        )
      end

      it "creates a new case transition (history) entry" do
        expect { service.call }.to change(CaseTransition.all, :size).by_at_least(1)
        expect(CaseTransition.last.event).to eq "add_data_received"
      end
    end

    context "when a failure" do
      it "does not save DataRequest when validation errors" do
        bad_params = params.clone
        bad_params.merge!(cached_num_pages: -20)
        service.instance_variable_set(:@params, bad_params)
        previous_cached_num_pages = data_request.cached_num_pages
        previous_cached_date_received = data_request.cached_date_received

        expect { service.call }.to change(CaseTransition.all, :size).by(0)
        expect(service.data_request.errors.size).to be > 0
        expect(service.result).to eq :error

        expect(data_request.reload.cached_num_pages).to eq previous_cached_num_pages
        expect(data_request.reload.cached_date_received).to eq previous_cached_date_received
      end

      it "only recovers from ActiveRecord exceptions" do
        allow_any_instance_of(DataRequest).to receive(:save!).and_raise(FakeError) # rubocop:disable RSpec/AnyInstance
        expect { service.call }.to raise_error FakeError
      end
    end
  end

  describe "#log_message" do
    it "creates a human readable case history message" do
      service.call

      expect(CaseTransition.last.message).to eq "HMP Brixton, All prison records: pages changed from 0 to 21"
    end
  end
end
