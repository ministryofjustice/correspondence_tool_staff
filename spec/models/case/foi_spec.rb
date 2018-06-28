require 'rails_helper'

describe Case::FOI::Standard do

  let(:no_postal)          { build :case, postal_address: nil             }
  let(:no_postal_or_email) { build :case, postal_address: nil, email: nil }
  let(:no_email)           { build :case, email: nil                      }

  describe '#subject' do
    it { should validate_length_of(:subject).is_at_most(100) }
  end

  context 'without a postal or email address' do
    it 'is invalid' do
      expect(no_postal_or_email).not_to be_valid
    end
  end

  context 'without a postal_address' do
    it 'is valid with an email address' do
      expect(no_postal).to be_valid
    end
  end

  context 'without an email address' do
    it 'is valid with a postal address' do
      expect(no_email).to be_valid
    end
  end

  describe 'papertrail versioning', versioning: true do

    before(:each) do
      @kase = create :foi_case, name: 'aaa', email: 'aa@moj.com', received_date: Date.today, subject: 'subject A', postal_address: '10 High Street', requester_type: 'journalist'
      @kase.update!(name: 'bbb', email: 'bb@moj.com', received_date: 1.day.ago, subject: 'subject B', postal_address: '20 Low Street', requester_type: 'offender')
    end

    it 'saves all values in the versions object hash' do
      version_hash = YAML.load(@kase.versions.last.object)
      expect(version_hash['email']).to eq 'aa@moj.com'
      expect(version_hash['received_date']).to eq Date.today
      expect(version_hash['subject']).to eq 'subject A'
      expect(version_hash['postal_address']).to eq '10 High Street'
      expect(version_hash['requester_type']).to eq 'journalist'
    end

    it 'can reconsititue a record from a version (except for received_date)' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.email).to eq 'aa@moj.com'
      expect(original_kase.subject).to eq 'subject A'
      expect(original_kase.postal_address).to eq '10 High Street'
      expect(original_kase.requester_type).to eq 'journalist'
    end

    it 'reconstitutes the received date' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.received_date).to eq Date.today
    end
  end
end
