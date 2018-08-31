require 'rails_helper'

describe Case::OverturnedICO::SARDecorator do

  let(:overturned_sar)    { create(:overturned_ico_sar) }
  let(:decorated_case)    { overturned_sar.decorate }

  describe '#internal_deadline' do
    it 'returns the internal deadline' do
      Timecop.freeze(Time.new(2017, 5, 2, 9, 45, 33 )) do
        flagged_case = create(:case, :flagged).decorate
        expect(flagged_case.internal_deadline).to eq '16 May 2017'
      end
    end
  end

  describe '#original_case_description' do
    it 'returns pretty description' do
      expect(decorated_case.original_case_description).to eq(
          "ICO appeal (SAR) #{overturned_sar.original_ico_appeal.number}")
    end

  end

end



