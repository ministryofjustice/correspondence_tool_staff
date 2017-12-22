require 'rails_helper'

describe Case::SAR do

  context 'validates that SAR-specific fields are not blank' do
    it 'is not valid' do

      kase = build :sar_case, subject_full_name: nil, subject_type: nil, third_party: nil
      ap kase

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["can't be blank"])
      expect(kase.errors[:subject_type]).to eq(["can't be blank"])
      expect(kase.errors[:third_party]).to eq(["can't be blank"])
    end
  end

end
