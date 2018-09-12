require "rails_helper"

describe Case::ICO::BaseDecorator do
  let(:closed_ico_foi_case)        { (create :closed_ico_foi_case).decorate }
  let(:closed_overturned_foi_case) { (create :closed_ico_foi_case,
                                      :overturned_by_ico).decorate }


  it 'instantiates the correct decorator' do
    expect(Case::ICO::Base.new.decorate).to be_instance_of Case::ICO::BaseDecorator
  end

  describe '#formatted_date_ico_decision_received' do
    it 'returns a formated date' do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.formatted_date_ico_decision_received).to eq '13 Aug 2017'
    end
  end

  describe '#ico_decision_summary' do
    it 'returns a just the summary' do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.ico_decision_summary)
          .to eq '<p><strong>MoJ&#39;s decision has been upheld by the ICO </strong>on 13 Aug 2017</p>'
    end

    it 'returns summary and comment' do
      closed_overturned_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      closed_overturned_foi_case.ico_decision_comment = 'Today is a good day'
      expect(closed_overturned_foi_case.ico_decision_summary)
          .to eq "<p><strong>MoJ&#39;s decision has been overturned by the ICO </strong>on 13 Aug 2017</p><p>Today is a good day</p>"
    end
  end


end
