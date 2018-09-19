require "rails_helper"

describe Case::OverturnedICO::BaseDecorator do
  let(:overturned_ico_sar) {create(:overturned_ico_sar).decorate }

  it 'instantiates the correct decorator' do
    expect(Case::OverturnedICO::Base.new.decorate).to be_instance_of Case::OverturnedICO::BaseDecorator
  end

  describe '#internal_deadline' do
    it 'returns the internal deadline' do
      Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
        overturned_ico_sar = create(:overturned_ico_sar).decorate
        expect(overturned_ico_sar.internal_deadline).to eq '21 Apr 2017'
      end
    end
  end

  describe '#formatted_date_ico_decision_received' do
    it 'returns a formated date' do
      overturned_ico_sar = create(:overturned_ico_sar).decorate
      overturned_ico_sar.original_ico_appeal.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(overturned_ico_sar.formatted_date_ico_decision_received).to eq '13 Aug 2017'
    end
  end

  describe '#ico_decision_summary' do
    it 'returns a just the summary' do
      overturned_ico_sar.original_ico_appeal.date_ico_decision_received = Date.new(2017, 8, 13)
      overturned_ico_sar.original_ico_appeal.ico_decision = :upheld
      expect(overturned_ico_sar.ico_decision_summary)
          .to eq '<p><strong>MoJ&#39;s decision has been upheld by the ICO </strong>on 13 Aug 2017</p>'
    end

    it 'returns summary and comment' do
      overturned_ico_sar.original_ico_appeal.date_ico_decision_received = Date.new(2017, 8, 13)
      overturned_ico_sar.original_ico_appeal.ico_decision_comment = 'Today is a good day'
      overturned_ico_sar.original_ico_appeal.ico_decision = :overturned
      expect(overturned_ico_sar.ico_decision_summary)
          .to eq "<p><strong>MoJ&#39;s decision has been overturned by the ICO </strong>on 13 Aug 2017</p><p>Today is a good day</p>"
    end
  end

  describe '#original_case_description' do
    context "Overturned SAR" do
      let(:overturned_sar)    { create(:overturned_ico_sar) }
      let(:decorated_case)    { overturned_sar.decorate }

      it 'returns pretty description' do
        expect(decorated_case.original_case_description).to eq(
            "ICO appeal (SAR) #{overturned_sar.original_ico_appeal.number}")
      end
    end

    context "Overturned FOI" do
      let(:overturned_foi)    { create(:overturned_ico_foi) }
      let(:decorated_case)    { overturned_foi.decorate }

      it 'returns pretty description' do
        expect(decorated_case.original_case_description).to eq(
            "ICO appeal (FOI) #{overturned_foi.original_ico_appeal.number}")
      end
    end
  end
end
