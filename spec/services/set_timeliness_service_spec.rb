require 'rails_helper'

describe SetDraftTimelinessService do
  let(:kase)      { find_or_create :pending_dacu_clearance_case }
  let(:tue_may_23) { Time.utc(2017, 5, 23, 12, 0, 0) }

  before(:each) do
    @service = SetDraftTimelinessService.new(kase: kase)
  end


  it 'sets the draft timeliness date' do
    Timecop.freeze tue_may_23 do
      @service.call
      expect(kase.date_draft_compliant)
          .to eq kase.transitions.where(event: 'add_responses').last.created_at.to_date
    end
  end
end
