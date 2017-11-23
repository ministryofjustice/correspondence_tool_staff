require 'rails_helper'

describe FoiTimelinessReviewDecorator, type: :model do

  it 'pretty prints FOITimelinessReview' do
    kases = (create :foi_timeliness_review).decorate
    expect(kases.pretty_type).to eq 'FOI - Internal review for timeliness'
  end
end
