require "rails_helper"

describe Case::FOI::TimelinessReviewDecorator, type: :model do
  it "pretty prints Case::FOI::TimelinessReview" do
    kases = (create :timeliness_review).decorate
    expect(kases.pretty_type).to eq "FOI - Internal review for timeliness"
  end
end
