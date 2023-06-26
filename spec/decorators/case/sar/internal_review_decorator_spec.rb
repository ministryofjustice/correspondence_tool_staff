require "rails_helper"

describe Case::SAR::InternalReviewDecorator do
  let(:subject_with_reference) { "IR of 12345 - subject details" }
  let(:sar_ir_case) do
    create(:sar_internal_review).decorate
  end

  let(:sar_ir_case_with_orignal_case_referenced_in_subject) do
    create(:sar_internal_review, subject: "IR of 12345 - subject details").decorate
  end

  it "instantiates the correct decorator" do
    decorator = Case::SAR::InternalReview.new.decorate
    expect(decorator).to be_instance_of described_class
  end

  describe "#pretty_type" do
    it "pretty prints case type name" do
      expect(sar_ir_case.decorate.pretty_type).to eq "SAR Internal Review - compliance"
    end
  end

  describe "#pretty_outcome_reasons" do
    it "pretty prints outcome_reasons" do
      stub_reasons = [
        instance_double(CaseClosure::OutcomeReason),
        instance_double(CaseClosure::OutcomeReason),
        instance_double(CaseClosure::OutcomeReason),
      ]

      stub_reasons.each_with_index do |reason, i|
        allow(reason).to receive(:name).and_return("Outcome Reason #{i + 1}")
      end

      kase = sar_ir_case.decorate
      allow(kase.object).to receive(:outcome_reasons).and_return(stub_reasons)

      expected_string = "Outcome Reason 1,<br>Outcome Reason 2,<br>Outcome Reason 3"
      expect(kase.pretty_outcome_reasons).to eq expected_string
    end
  end

  describe "#subject_type_display" do
    it "humanizes the subject_type for display" do
      kase = sar_ir_case.decorate
      expect(kase.subject_type_display).to eq "Offender"
    end
  end

  describe "#subject_with_original_case_reference" do
    it "Adds original case reference to subject line if not present" do
      subject_line = "IR of #{sar_ir_case.original_case.number} - #{sar_ir_case.subject}"
      kase = sar_ir_case.decorate
      expect(kase.subject_with_original_case_reference).to eq subject_line
    end

    it "Does not add original case reference to subject line if aready present" do
      kase = sar_ir_case_with_orignal_case_referenced_in_subject.decorate
      expect(kase.subject_with_original_case_reference).to eq subject_with_reference
    end
  end
end
