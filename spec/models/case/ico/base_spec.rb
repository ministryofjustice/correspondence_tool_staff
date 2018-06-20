require 'rails_helper'

describe Case::ICO::Base do
  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns false' do
      kase = create :ico_foi_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be false
    end
  end
end
