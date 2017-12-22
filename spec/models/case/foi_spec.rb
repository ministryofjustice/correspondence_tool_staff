require 'rails_helper'

describe Case::FOI do

  context 'validates that SAR-specific fields are blank' do
    it 'is not valid' do

      kase = build :case, subject_full_name: 'Stephen Richards', subject_type: 'Offender', third_party: false
      expect(kase).not_to be_valid
      ap kase.errors
    end

  end


end
