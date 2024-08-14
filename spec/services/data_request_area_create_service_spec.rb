require "rails_helper"

class FakeError < ArgumentError; end

describe DataRequestAreaCreateService do
  let(:user) { create :user }
  let(:offender_sar_case) { create :offender_sar_case }
  let(:data_request_area_attributes) { { data_request_area_type: "prison" } }
  let(:service) do
    described_class.new(
      kase: offender_sar_case,
      user:,
      data_request_area_params: data_request_area_attributes,
    )
  end

  describe "#initialize" do
    it "requires a case and user" do
      expect(service.instance_variable_get(:@case)).to eq offender_sar_case
      expect(service.instance_variable_get(:@user)).to eq user
    end

    # No restriction on case type as managed by model
    it "ignores case type" do
      new_service = described_class.new(
        kase: create(:foi_case),
        user:,
        data_request_area_params: data_request_area_attributes,
      )

      expect(new_service).to be_instance_of described_class
    end
  end

  describe "#call" do
    context "when on success" do
      it "saves DataRequestArea" do
        expect { service.call }.to change(DataRequestArea.all, :size).by(1)
        expect(service.result).to eq :ok
      end

      it "creates a data request area with the attributes given" do
        service.call
        expect(service.data_request_area).to be_persisted
        expect(service.data_request_area.data_request_area_type).to eq "prison"
      end
    end

    context "when on failure" do
      it "does not save DataRequestArea when validation errors" do
        params = data_request_area_attributes.clone
        params.merge!({ data_request_area_type: "" })

        service = described_class.new(
          kase: offender_sar_case,
          user:,
          data_request_area_params: params,
        )

        expect { service.call }.to change(DataRequestArea.all, :size).by(0)
        expect(service.case.errors.size).to be > 0
        expect(service.result).to eq :error
      end

      it "does not save DataRequestArea when nothing to process" do
        service = described_class.new(
          kase: offender_sar_case,
          user:,
          data_request_area_params: {},
        )

        expect { service.call }.to change(DataRequestArea.all, :size).by(0)
        expect(service.result).to eq :error
      end

      it "only recovers from ActiveRecord exceptions" do
        allow_any_instance_of(Case::Base).to receive(:save!).and_raise(FakeError) # rubocop:disable RSpec/AnyInstance
        expect { service.call }.to raise_error FakeError
      end
    end
  end
end
