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

      context "and the form model has the values merged" do
        it "returns false" do
          expect(case_form.valid_attributes?(params)).to be false
        end
      end

      context "and the form model does not have the values merged" do
        it "returns false" do
          expect(case_form.valid_attributes?(params)).to be false
        end
      end
    end
  end
end
