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

  describe '#pretty_ico_decision' do

    it 'returns upheld descrption' do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.pretty_ico_decision)
          .to eq 'Upheld by ICO'
    end

    it 'returns overturned descrption' do
      closed_overturned_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_overturned_foi_case.pretty_ico_decision)
          .to eq "Overturned by ICO"
    end
  end

  describe '#original_internal_deadline' do
    it 'returns a formatted date' do
      closed_ico_foi_case.object.original_internal_deadline = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_internal_deadline).to eq '13 Aug 2017'
    end
  end

  describe '#original_external_deadline' do
    it 'returns a formatted date' do
      closed_ico_foi_case.object.original_external_deadline = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_external_deadline).to eq '13 Aug 2017'
    end
  end

  describe '#original_date_responded' do
    it 'returns a formatted date' do
      closed_ico_foi_case.object.original_date_responded = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.original_date_responded).to eq '13 Aug 2017'
    end
  end
end
