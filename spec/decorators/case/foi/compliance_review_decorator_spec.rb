require "rails_helper"

describe Case::FOI::ComplianceReviewDecorator, type: :model do
  it "pretty prints Case::FOI::ComplianceReview" do
    kase = (create :compliance_review).decorate
    expect(kase.pretty_type).to eq "FOI - Internal review for compliance"
  end
end
