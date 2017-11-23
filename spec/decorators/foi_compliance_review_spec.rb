require 'rails_helper'

describe FoiComplianceReviewDecorator, type: :model do

  it 'pretty prints FOIComplianceReview' do
    kase = (create :foi_compliance_review).decorate
    expect(kase.pretty_type).to eq 'FOI - Internal review for compliance'
  end
end
