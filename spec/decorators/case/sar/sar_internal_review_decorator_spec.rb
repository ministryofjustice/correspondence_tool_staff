require "rails_helper"

describe Case::SAR::InternalReviewDecorator do
  let(:decorated_sar_internal_review_case) { 
    create(:sar_internal_review).decorate 
  }

  it 'instantiates the correct decorator' do
    decorator = Case::SAR::InternalReview.new.decorate
    expect(decorator).to be_instance_of Case::SAR::InternalReviewDecorator
  end

  describe '#pretty_type' do
    it 'pretty prints case type name' do
      expect(decorated_sar_internal_review_case.decorate.pretty_type).to eq 'SAR Internal Review'
    end
  end

  describe '#subject_type_display' do
    it 'humanizes the subject_type for display' do
      kase = decorated_sar_internal_review_case.decorate
      expect(kase.subject_type_display).to eq 'Offender'
    end
  end
end
