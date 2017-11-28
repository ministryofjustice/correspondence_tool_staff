require 'rails_helper'

describe FOITimelinessReviewDecorator, type: :model do

  it 'pretty prints FOITimelinessReview' do
    kases = (create :FOI_timeliness_review).decorate
    expect(kases.pretty_type).to eq 'FOI - Internal review for timeliness'
  end
end
