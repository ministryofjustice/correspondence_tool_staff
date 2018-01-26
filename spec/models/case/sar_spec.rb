require 'rails_helper'

describe Case::SAR do
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
        expect {
          build(:sar_case, subject_type: 'plumber')
        }.to raise_error ArgumentError
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:sar_case, subject_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ["can't be blank"]
      end
    end
  end

  describe 'papertrail versioning', versioning: true do
    before(:each) do
      @kase = create :sar_case,
                     name: 'aaa',
                     email: 'aa@moj.com',
                     received_date: Date.today,
                     subject: 'subject A'
      @kase.update! name: 'bbb',
                    email: 'bb@moj.com',
                    received_date: 1.day.ago,
                    subject: 'subject B'
    end

    xit 'saves all values in the versions object hash' do
      version_hash = YAML.load(@kase.versions.last.object)
      expect(version_hash['email']).to eq 'aa@moj.com'
      expect(version_hash['received_date']).to eq Date.today
      expect(version_hash['subject']).to eq 'subject A'
    end

    it 'can reconsititue a record from a version (except for received_date)' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.email).to eq 'aa@moj.com'
      expect(original_kase.subject).to eq 'subject A'
    end

    it 'does not reconstitute the received date properly because of an interaction with govuk_date_fields' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.received_date).to eq 1.day.ago.to_date
    end
  end

  describe 'use_subject_as_requester callback' do
    context 'on create' do
      it 'does not change the requester when present' do
        sar_case = create :sar_case, name: 'Bob', subject_full_name: 'Doug'
        expect(sar_case.reload.name).to eq 'Bob'
      end

      it 'uses the subject as the requester if not present on update' do
        sar_case = create :sar_case, name: '', subject_full_name: 'Doug'
        expect(sar_case.reload.name).to eq 'Doug'
      end
    end

    context 'on update' do
      it 'does not change the requester when present' do
        sar_case = create :sar_case
        sar_case.update! name: 'Bob', subject_full_name: 'Doug'
        expect(sar_case.name).to eq 'Bob'
      end

      it 'uses the subject as the requester if not present on update' do
        sar_case = create :sar_case
        sar_case.update! name: '', subject_full_name: 'Doug'
        expect(sar_case.name).to eq 'Doug'
      end
    end
  end
end

