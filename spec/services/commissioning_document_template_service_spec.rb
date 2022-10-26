require 'rails_helper'

describe CommissioningDocumentTemplateService do
  let(:data_request) { FactoryBot.build(:data_request) }
  let(:template_type) { :prison }
  subject { described_class.new(data_request: data_request, template_type: template_type) }

  describe "#initialize" do
    it "returns error when template_type is invalid" do
      expect{
        described_class.new(data_request: data_request, template_type: "invalid")
      }.to raise_error(described_class::InvalidTemplateError)
    end

    it "returns error when data_request is invalid" do
      expect{
        described_class.new(data_request: "invalid", template_type: template_type)
      }.to raise_error(described_class::InvalidDataRequestError)
    end
  end

  describe "#context" do
    let(:template_data) { { prison_number: "123456" } }

    before do
      allow_any_instance_of(CommissioningDocumentTemplate::Prison).to receive(:context).and_return(template_data)
    end

    it "returns data for the selected template type" do
      expect(subject.context).to eq template_data
    end
  end
end
