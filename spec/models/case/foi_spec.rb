require 'rails_helper'

describe Case::FOI do

  context 'validates that SAR-specific fields are blank' do
    it 'is not valid' do

      kase = build :case, subject_full_name: 'Stephen Richards', subject_type: 'Offender', third_party: false
      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(['must be blank'])
      expect(kase.errors[:subject_type]).to eq(['must be blank'])
      expect(kase.errors[:third_party]).to eq(['must be blank'])
    end

  end


end
