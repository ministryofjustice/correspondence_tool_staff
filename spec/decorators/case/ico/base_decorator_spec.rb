require "rails_helper"

describe Case::ICO::BaseDecorator do
  let(:closed_ico_foi_case) { (create :closed_ico_foi_case).decorate }

  it 'instantiates the correct decorator' do
    expect(Case::ICO::Base.new.decorate).to be_instance_of Case::ICO::BaseDecorator
  end

  describe '#date_decision_received' do
    it 'returns a formated date' do
      closed_ico_foi_case.object.date_ico_decision_received = Date.new(2017, 8, 13)
      expect(closed_ico_foi_case.date_decision_received).to eq '13 Aug 2017'
    end
  end


end
