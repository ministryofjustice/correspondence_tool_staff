require 'rails_helper'

describe FOIComplianceReviewDecorator, type: :model do

  it 'pretty prints FOIComplianceReview' do
    kase = (create :FOI_compliance_review).decorate
    expect(kase.pretty_type).to eq 'FOI - Internal review for compliance'
  end
end
