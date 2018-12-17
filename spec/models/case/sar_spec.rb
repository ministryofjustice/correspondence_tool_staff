# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

require 'rails_helper'

describe Case::SAR do

  context 'validates that SAR-specific fields are not blank' do
    it 'is not valid' do

      kase = build :sar_case, subject_full_name: nil, subject_type: nil, third_party: nil

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["can't be blank"])
      expect(kase.errors[:third_party]).to eq(["Please choose yes or no"])
    end
  end

  describe 'subject attribute' do
    it { should validate_presence_of(:subject) }
    it { should validate_length_of(:subject).is_at_most(100) }
  end

  describe '#subject_type' do
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

  describe '#reply_method' do
    it { should validate_presence_of(:reply_method) }
    it { should allow_values('send_by_email', 'send_by_post').for(:reply_method) }
  end

  describe '#email' do
    it 'validates presence of email when reply is to be sent by email' do
      kase = build :sar_case, reply_method: :send_by_email, email: ''
      expect(kase).not_to be_valid
      expect(kase.errors[:email]).to eq ["can't be blank"]
    end
  end

  describe '#postal_address' do
    it 'validates presence of postal address when reply is to be sent by post' do
      kase = build :sar_case, reply_method: :send_by_post, postal_address: ''
      expect(kase).not_to be_valid
      expect(kase.errors[:postal_address]).to eq ["can't be blank"]
    end
  end

  describe 'third party details' do
    describe '#name' do
      it 'validates presence of name when third party is true' do
        kase = build :sar_case, third_party: true, name: ''
        expect(kase).not_to be_valid
        expect(kase.errors[:name]).to eq ["can't be blank"]
      end

      it 'does not validates presence of name when third party is false' do
        kase = build :sar_case, third_party: false, name: ''
        expect(kase).to be_valid
      end
    end

    describe 'third party relationship' do
      it 'must be persent when thrid party is true' do
        kase = build :sar_case, third_party: true, third_party_relationship: ''
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["can't be blank"]
      end

      it 'does not validates presence of third party relationship when third party is false' do
        kase = build :sar_case, third_party: false, third_party_relationship: ''
        expect(kase).to be_valid
      end
    end
  end

  describe '#message' do
    it 'validates presence if uploaded_request_files is missing on create' do
      kase = build :sar_case, uploaded_request_files: [], message: ''
      expect(kase).not_to be_valid
      expect(kase.errors[:message])
        .to eq ["can't be blank if no request files attached"]
    end

    it 'validates presence if attached request files is missing on update' do
      kase = create :sar_case, uploaded_request_files: [], message: 'foo'
      expect(kase).to be_valid
      kase.update_attributes(message: '')
      expect(kase).not_to be_valid
      expect(kase.errors[:message])
        .to eq ["can't be blank if no request files attached"]
    end

    it 'can be empty on create if uploaded_request_files is present' do
      kase = build :sar_case,
                   uploaded_request_files: ["#{Faker::Internet.slug}.pdf"],
                   message: ''
      expect(kase).to be_valid
    end

    it 'can be empty on update if attached request files is present' do
      kase = create :sar_case,
                    uploaded_request_files: ["#{Faker::Internet.slug}.pdf"],
                    uploading_user: create(:manager),
                    message: 'foo'
      expect(kase).to be_valid
      kase.update_attributes(message: '')
      expect(kase).to be_valid
    end
  end

  describe '#within_escalation_deadline?' do
    it 'returns false' do
      sar = build(:sar_case)
      expect(sar.within_escalation_deadline?).to be_falsey
    end
  end

  describe '#uploaded_request_files' do
    it 'validates presence if message is missing' do
      kase = build :sar_case, uploaded_request_files: [], message: ''
      expect(kase).not_to be_valid
      expect(kase.errors[:uploaded_request_files])
        .to eq ["can't be blank if no case details entered"]
    end

    it 'does validates presence if message is present' do
      kase = build :sar_case,
                   uploaded_request_files: [],
                   message: 'A message'
      expect(kase).to be_valid
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

    it 'reconstitutes the received date properly' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.received_date).to eq Date.today
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

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns true' do
      kase = create :sar_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be true
    end
  end

  describe '.searchable_fields_and_ranks' do
    it 'includes subject full name' do
      expect(Case::SAR.searchable_fields_and_ranks).to include({subject_full_name: 'B'})
    end
  end

end
