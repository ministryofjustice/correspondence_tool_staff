require 'rails_helper'

describe Case::OverturnedICO::SARDecorator do

  let(:overturned_sar)    { create(:overturned_ico_sar) }
  let(:decorated_case)    { overturned_sar.decorate }

  describe '#type_printer' do
    it 'pretty prints Case' do
      expect(decorated_case.pretty_type).to eq 'ICO overturned (SAR)'
    end
  end

  describe '#original_case_description' do
    it 'returns pretty description' do
      expect(decorated_case.original_case_description).to eq(
          "ICO appeal (SAR) #{overturned_sar.original_ico_appeal.number}")
    end

  end

end



