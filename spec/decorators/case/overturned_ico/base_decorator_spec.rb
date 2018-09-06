require "rails_helper"

describe Case::OverturnedICO::BaseDecorator do

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


end
