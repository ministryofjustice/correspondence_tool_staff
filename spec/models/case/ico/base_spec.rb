require 'rails_helper'

describe Case::ICO::Base do
  describe '.type_abbreviation' do
    subject { described_class.type_abbreviation }
    it { should eq 'ICO' }
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns false' do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end
end
