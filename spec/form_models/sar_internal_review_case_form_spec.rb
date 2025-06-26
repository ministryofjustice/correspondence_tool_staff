require "rails_helper"

RSpec.describe SARInternalReviewCaseForm do
  let(:case_form) { create(:sar_internal_review).decorate }

  it "can be created" do
    expect(case_form).to be_an_instance_of Case::SAR::InternalReview
  end

  describe "#steps" do
    it "returns the list of steps" do
      expect(case_form.steps).to eq %w[
        link-sar-case
        confirm-sar
        case-details
      ]
    end
  end

  describe "Original sar attributes to copy" do
    correct_attributes = %i[
      delivery_method
      email
      name
      postal_address
      requester_type
      subject
      subject_full_name
      subject_type
      third_party
      third_party_relationship
      reply_method
    ].freeze

    it "lists the correct attributes to copy over to the SAR IR" do
      expect(case_form.original_sar_attributes_to_copy).to match(correct_attributes)
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
  end
end
