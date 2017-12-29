require 'rails_helper'

describe Case::SAR::NonOffender do
  context 'validates that SAR-specific fields are not blank' do
    it 'is not valid' do

      kase = build :sar_case, subject_full_name: nil, subject_type: nil, third_party: nil

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["can't be blank"])
      expect(kase.errors[:third_party]).to eq(["can't be blank"])
    end
  end

  context 'validation of subject type' do
    context 'valid values' do
      it 'does not error' do
        expect(build(:sar_case, subject_type: 'offender')).to be_valid
        expect(build(:sar_case, subject_type: 'staff')).to be_valid
        expect(build(:sar_case, subject_type: 'member_of_the_public')).to be_valid
      end
    end

    context 'invalid value' do
      it 'errors' do
        kase = build(:sar_case, subject_type: 'plumber')
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ['is not a valid subject type']
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:sar_case, subject_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ['is not a valid subject type']
      end
    end
  end

end

