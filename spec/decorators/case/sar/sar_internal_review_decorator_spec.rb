require "rails_helper"

describe Case::SAR::InternalReviewDecorator do

  let(:subject_with_reference) { "IR of 12345 - subject details" }
  let(:sar_ir_case) { 
    create(:sar_internal_review).decorate 
  }


  let(:sar_ir_case_with_orignal_case_referenced_in_subject) { 
    create(:sar_internal_review, subject: "IR of 12345 - subject details" ).decorate 
  }

  it 'instantiates the correct decorator' do
    decorator = Case::SAR::InternalReview.new.decorate
    expect(decorator).to be_instance_of Case::SAR::InternalReviewDecorator
  end

  describe '#pretty_type' do
    it 'pretty prints case type name' do
      expect(sar_ir_case.decorate.pretty_type).to eq 'SAR Internal Review'
    end
  end

  describe '#subject_type_display' do
    it 'humanizes the subject_type for display' do
      kase = sar_ir_case.decorate
      expect(kase.subject_type_display).to eq 'Offender'
    end
  end

  describe '#subject_with_original_case_reference' do
    it 'Adds original case reference to subject line if not present' do
      subject_line = "IR of 211130001 - new sar ir case subject 3"
      kase = sar_ir_case.decorate
      expect(kase.subject_with_original_case_reference).to eq subject_line
    end

    it 'Does not add original case reference to subject line if aready present' do
      kase = sar_ir_case_with_orignal_case_referenced_in_subject.decorate
      expect(kase.subject_with_original_case_reference).to eq subject_with_reference
    end
  end
end
