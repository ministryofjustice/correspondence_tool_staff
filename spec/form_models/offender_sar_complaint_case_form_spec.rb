require "rails_helper"

RSpec.describe OffenderSARComplaintCaseForm do
  let(:case_form) { create(:offender_sar_complaint).decorate }

  it "can be created" do
    expect(case_form).to be_an_instance_of Case::SAR::OffenderComplaint
  end

  describe "#steps" do
    it "returns the list of steps" do
      expect(case_form.steps).to eq %w[
        link-offender-sar-case
        confirm-offender-sar
        complaint-type
        requester-details
        recipient-details
        requested-info
        request-details
        date-received
        set-deadline
      ]
    end
  end

  describe "#valid_attributes?" do
    context "when params is empty" do
      params = ActionController::Parameters.new({}).permit!

      it "returns false" do
        expect(case_form.valid_attributes?(params)).to be false
      end
    end

    context "when params is nil" do
      let(:params) { nil }

      it "returns false" do
        expect(case_form.valid_attributes?(params)).to be false
      end
    end

    context "when params is set and not valid" do
      let(:params) do
        ActionController::Parameters.new(
          case_form: { name: "", postal_address: "address" },
        ).require(:case_form).permit(:name, :postal_address)
      end

      it "returns false" do
        expect(case_form.valid_attributes?(params)).to be false
      end
    end

    context "when date_received entered" do
      before { case_form.current_step = "date-received" }

      context "when day is 0" do
        let(:params) do
          ActionController::Parameters.new(
            received_date_dd: "0",
            received_date_mm: "6",
            received_date_yyyy: Time.zone.today.year.to_s,
          ).permit!
        end

        it "returns false" do
          expect(case_form.valid_attributes?(params)).to be false
        end

        it "adds an invalid date error on received_date" do
          case_form.valid_attributes?(params)
          expect(case_form.errors[:received_date]).to include("must be a valid date")
        end
      end

      context "when received_date is valid" do
        let(:params) do
          ActionController::Parameters.new(
            received_date_dd: Time.zone.today.day.to_s,
            received_date_mm: Time.zone.today.month.to_s,
            received_date_yyyy: Time.zone.today.year.to_s,
          ).permit!
        end

        it "returns true" do
          expect(case_form.valid_attributes?(params)).to be true
        end
      end
    end
  end
end
