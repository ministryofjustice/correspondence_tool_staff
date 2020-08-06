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

describe Case::SAR::Offender do

  context 'factory should be valid' do
    it 'is valid' do
      kase = build :offender_sar_case

      expect(kase).to be_valid
    end
  end

  context 'validates that SAR-specific fields are not blank' do
    it 'is not valid' do

      kase = build :offender_sar_case, subject_full_name: nil, subject_type: nil, third_party: nil, flag_as_high_profile: nil

      expect(kase).not_to be_valid
      expect(kase.errors[:subject_full_name]).to eq(["can't be blank"])
      expect(kase.errors[:third_party]).to eq(["can't be blank"])
    end
  end

  describe '#subject_type' do
    context 'valid values' do
      it 'does not error' do
        expect(build(:offender_sar_case, subject_type: 'detainee')).to be_valid
        expect(build(:offender_sar_case, subject_type: 'ex_detainee')).to be_valid
        expect(build(:offender_sar_case, subject_type: 'ex_offender')).to be_valid
        expect(build(:offender_sar_case, subject_type: 'offender')).to be_valid
        expect(build(:offender_sar_case, subject_type: 'probation_service_user')).to be_valid
        expect(build(:offender_sar_case, subject_type: 'ex_probation_service_user')).to be_valid
      end
    end

    context 'invalid value' do
      it 'errors' do
        expect {
          build(:offender_sar_case, subject_type: 'plumber')
        }.to raise_error ArgumentError
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:offender_sar_case, subject_type: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:subject_type]).to eq ["can't be blank"]
      end
    end
  end

  describe '#recipient' do
    context 'valid values' do
      it 'does not error' do
        expect(build(:offender_sar_case, recipient: 'subject_recipient')).to be_valid
        expect(build(:offender_sar_case, recipient: 'requester_recipient')).to be_valid
        expect(build(:offender_sar_case,
                    recipient: 'third_party_recipient',
                    third_party: false,
                    third_party_name: 'test',
                    third_party_relationship: 'test'
                    )).to be_valid
      end
    end

    context 'invalid value' do
      it 'errors' do
        expect {
          build(:offender_sar_case, recipient: 'user')
        }.to raise_error ArgumentError
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:offender_sar_case, recipient: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:recipient]).to eq ["can't be blank"]
      end
    end
  end

  describe '#postal_address' do
    context 'valid values' do
      it 'validates when address is set' do
        kase = build(:offender_sar_case, :third_party, postal_address: '22 Acacia Avenue')
        expect(kase).to be_valid
      end
    end

    context 'invalid values' do
      it 'validates presence of postal address when recipient is third party' do
        kase = build :offender_sar_case, :third_party, postal_address: ''
        expect(kase).not_to be_valid
        expect(kase.errors[:postal_address]).to eq ["can't be blank"]
      end
    end
  end

  describe '#date_of_birth' do
    context 'valid values' do
      it 'validates date of birth' do
        kase = build :offender_sar_case

        expect(kase).to validate_presence_of(:date_of_birth)
        expect(kase).to allow_values('01-01-1967').for(:date_of_birth)
      end
    end

    context 'invalid value' do
      it 'errors' do
        expect {
          build(:offender_sar_case, date_of_birth: 'wibble')
        }.to raise_error ArgumentError
      end
    end

    context 'date of birth cannot be in future' do
      it 'errors' do
        kase = build(:offender_sar_case, date_of_birth: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["can't be in the future."]
      end
    end

    context 'nil' do
      it 'errors' do
        kase = build(:offender_sar_case, date_of_birth: nil)
        expect(kase).not_to be_valid
        expect(kase.errors[:date_of_birth]).to eq ["can't be blank"]
      end
    end
  end

  describe '#received_date' do
    context 'valid values' do
      it 'validates received date' do
        kase = build :offender_sar_case
        test_date = 4.business_days.ago.strftime("%d-%m-%Y")

        expect(kase).to validate_presence_of(:received_date)
        expect(kase).to allow_values(test_date).for(:received_date)
      end
    end

    context 'invalid value' do
      it 'errors' do
        expect {
          build(:offender_sar_case, received_date: 'wibble')
        }.to raise_error ArgumentError
      end
    end

    context 'received date cannot be in future' do
      it 'errors' do
        kase = build(:offender_sar_case, received_date: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:received_date]).to eq ["can't be in the future."]
      end
    end
  end

  describe '#request_dated' do
    context 'invalid value' do
      it 'errors' do
        expect {
          build(:offender_sar_case, request_dated: 'wibble')
        }.to raise_error ArgumentError
      end
    end

    context 'request_dated date cannot be in future' do
      it 'errors' do
        kase = build(:offender_sar_case, request_dated: 1.day.from_now)
        expect(kase).not_to be_valid
        expect(kase.errors[:request_dated]).to eq ["can't be in the future."]
      end
    end
  end

  describe 'third party details' do
    describe 'third_party_names' do
      it 'validates third party names when third party is true' do
        kase = build :offender_sar_case, :third_party, third_party_name: '', third_party_company_name: ''
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["can't be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["can't be blank if representative name not given"]
      end

      it 'validates third party names when recipient is third party' do
        kase = build :offender_sar_case, third_party: false, third_party_name: '',
                      third_party_company_name: '', recipient: 'third_party_recipient'
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_name]).to eq ["can't be blank if company name not given"]
        expect(kase.errors[:third_party_company_name]).to eq ["can't be blank if representative name not given"]
      end

      it 'does not validate third_party names when ecipient is not third party too' do
        kase = build :offender_sar_case, third_party: false, third_party_name: '',
                      third_party_company_name: '', recipient: 'subject_recipient'
        expect(kase).to be_valid
      end
    end


    describe 'third party relationship' do
      it 'must be present when thrid party is true' do
        kase = build :offender_sar_case, third_party: true, third_party_relationship: ''
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["can't be blank"]
      end

      it 'must be present when third party is false but recipient is third party' do
        kase = build :offender_sar_case, third_party: false, third_party_relationship: '',
                      recipient: 'third_party_recipient'
        expect(kase).not_to be_valid
        expect(kase.errors[:third_party_relationship]).to eq ["can't be blank"]
      end

      it 'does not validates presence of third party relationship when recipient is not third party' do
        kase = build :offender_sar_case, third_party: false, third_party_relationship: '',
                      recipient: 'subject_recipient'
        expect(kase).to be_valid
      end
    end
  end

  describe '#subject' do
    it 'is the same as subject full name' do
      kase = create :offender_sar_case
      expect(kase.subject).to eq kase.subject_full_name
      kase.update_attribute(:subject_full_name, "Bob Hope")
      expect(kase.subject).to eq 'Bob Hope'
    end
  end

  describe '#subject_name' do
    it 'is the same as subject_full_name' do
      kase = create :offender_sar_case
      expect(kase.subject_name).to eq kase.subject_full_name
      kase.update_attribute(:subject_full_name, "Bob Hope")
      expect(kase.subject_name).to eq 'Bob Hope'
    end
  end

  describe '#subject_address' do
    it 'returns a dummy string for now' do
      kase = create :offender_sar_case
      expect(kase.subject_address).to eq '22 Sample Address, Test Lane, Testingington, TE57ST'
    end
  end

  describe '#third_party_address' do
    it 'wraps the postal_address field' do
      kase = create :offender_sar_case
      expect(kase.third_party_address).to eq kase.postal_address
      kase.update_attribute(:postal_address, '11 The Road')
      expect(kase.third_party_address).to eq '11 The Road'
    end
  end

  describe '#requester_name' do
    it 'returns third_party_name if third_party request' do
      kase = create :offender_sar_case, :third_party
      expect(kase.requester_name).to eq kase.third_party_name
    end

    it 'returns subject_name if not third_party request' do
      kase = create :offender_sar_case
      expect(kase.requester_name).to eq kase.subject_name
    end
  end

  describe '#requester_address' do
    it 'returns third_party_address if third_party request' do
      kase = create :offender_sar_case, :third_party
      expect(kase.requester_address).to eq kase.third_party_address
    end

    it 'returns subject_address if not third_party request' do
      kase = create :offender_sar_case
      expect(kase.requester_address).to eq kase.subject_address
    end
  end

  describe '#recipient_name' do
    it 'returns third_party_name when subject not recipient' do
      kase = create :offender_sar_case, :third_party
      expect(kase.recipient_name).not_to eq kase.subject_name
      expect(kase.recipient_name).to eq kase.third_party_name
    end

    it 'returns subject_name if subject is recipient' do
      kase = create :offender_sar_case
      expect(kase.recipient_name).not_to eq kase.third_party_name
      expect(kase.recipient_name).to eq kase.subject_name
    end

    it 'returns nothing if third party and no name supplied' do
      kase = create :offender_sar_case, :third_party, third_party_name: ''

      expect(kase.recipient_name).to eq ''
    end
  end

  describe '#recipient_address' do
    it 'returns third_party_address if subject not recipient' do
      kase = create :offender_sar_case, recipient: "requester_recipient"
      expect(kase.recipient_address).to eq kase.third_party_address
    end

    it 'returns subject_address if if subject is recipient' do
      kase = create :offender_sar_case, recipient: "subject_recipient"
      expect(kase.recipient_address).to eq kase.subject_address
    end
  end


  # describe '#within_escalation_deadline?' do
  #   it 'returns false' do
  #     sar = build(:offender_sar_case)
  #     expect(sar.within_escalation_deadline?).to be_falsey
  #   end
  # end

  # describe '#uploaded_request_files' do
  #   it 'validates presence if message is missing' do
  #     kase = build :sar_case, uploaded_request_files: [], message: ''
  #     expect(kase).not_to be_valid
  #     expect(kase.errors[:uploaded_request_files])
  #       .to eq ["can't be blank if no case details entered"]
  #   end

  #   it 'does validates presence if message is present' do
  #     kase = build :sar_case,
  #                  uploaded_request_files: [],
  #                  message: 'A message'
  #     expect(kase).to be_valid
  #   end
  # end

  describe 'papertrail versioning', versioning: true do
    let(:kase) { create :offender_sar_case,
                           name: 'aaa',
                           email: 'aa@moj.com',
                           received_date: Date.today,
                           subject_full_name: 'subject A' }
    before(:each) do
      kase.update! name: 'bbb',
                    email: 'bb@moj.com',
                    received_date: 1.day.ago,
                    subject_full_name: 'subject B'
    end

    it 'can reconsititue a record from a version (except for received_date)' do
      original_kase = kase.versions.last.reify
      expect(original_kase.email).to eq 'aa@moj.com'
      expect(kase.subject_full_name).to eq 'subject B'
      expect(original_kase.subject_full_name).to eq 'subject A'
    end

    it 'reconstitutes the received date properly' do
      original_kase = kase.versions.last.reify
      expect(original_kase.received_date).to eq Date.today
    end
  end

  describe 'use_subject_as_requester callback' do
    context 'on create' do
      it 'does not change the requester when present' do
        offender_sar_case = create :offender_sar_case, name: 'Bob', subject_full_name: 'Doug'
        expect(offender_sar_case.reload.name).to eq 'Bob'
      end

      it 'uses the subject as the requester if not present on update' do
        offender_sar_case = create :offender_sar_case, name: '', subject_full_name: 'Doug'
        expect(offender_sar_case.reload.name).to eq 'Doug'
      end
    end

    context 'on update' do
      it 'does not change the requester when present' do
        offender_sar_case = create :offender_sar_case
        offender_sar_case.update! name: 'Bob', subject_full_name: 'Doug'
        expect(offender_sar_case.name).to eq 'Bob'
      end

      it 'uses the subject as the requester if not present on update' do
        offender_sar_case = create :offender_sar_case
        offender_sar_case.update! name: '', subject_full_name: 'Doug'
        expect(offender_sar_case.name).to eq 'Doug'
      end
    end
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns true' do
      kase = create :offender_sar_case
      expect(kase.requires_flag_for_disclosure_specialists?).to be true
    end
  end

  describe '.searchable_fields_and_ranks' do
    it 'includes subject full name' do
      expect(Case::SAR::Offender.searchable_fields_and_ranks).to include({
        message: 'D',
        name: 'A',
        number: 'A',
        other_subject_ids: 'B',
        previous_case_numbers: 'B',
        prison_number: 'B',
        responding_team_name: 'B',
        subject: 'C',
        subject_aliases: 'B',
        subject_full_name: 'A',
      })
    end
  end

  # describe 'deadline' do
  #   subject             { create :sar_case }
  #   let(:max_extension) { Settings.sar_extension_limit.to_i }

  #   describe '#deadline_extended' do
  #     it 'is false by default' do
  #       expect(subject.deadline_extended?).to be false
  #     end
  #   end

  #   describe '#deadline_extendable?' do
  #     it 'is true if external_deadline is less than max possible deadline' do
  #       max_statutory_deadline = subject.initial_deadline + max_extension.days

  #       expect(subject.deadline_extendable?).to eq true
  #       expect(subject.external_deadline).to be < max_statutory_deadline
  #     end

  #     it 'is false when already extended equal or beyond satutory limit' do
  #       sar = create :approved_sar
  #       initial_deadline = DateTime.new(2019, 01, 01)
  #       allow(sar).to receive(:initial_deadline) { initial_deadline }

  #       sar.external_deadline = initial_deadline + max_extension.days

  #       expect(sar.deadline_extendable?).to eq false
  #     end
  #   end

  #   describe '#initial_deadline' do
  #     it 'uses current external_deadline if not yet extended' do
  #       expect(subject.initial_deadline).to eq subject.external_deadline
  #     end

  #     it 'checks transitions for initial deadline' do
  #       extended_sar = create(:sar_case, :extended_deadline_sar)

  #       original_deadline = extended_sar
  #         .transitions
  #         .where(event: 'extend_sar_deadline')
  #         .order(:id)
  #         .first
  #         .original_final_deadline

  #       expect(extended_sar.initial_deadline).to eq original_deadline
  #     end
  #   end

  #   describe '#max_allowed_deadline_date' do
  #     it 'is 60 calendar days after the initial_deadline' do
  #       max_statutory_deadline = subject.initial_deadline + 60.days

  #       expect(subject.max_allowed_deadline_date).to eq max_statutory_deadline
  #     end
  #   end

  #   describe '#extend_deadline!' do
  #     let(:approved_sar)      { create :approved_sar }
  #     let(:initial_deadline)  { approved_sar.initial_deadline }
  #     let(:new_deadline)      { DateTime.new(2019, 01, 01) }

  #     it 'sets #deadline_extended to true' do
  #       expect { approved_sar.extend_deadline!(new_deadline) }.to \
  #         change(approved_sar, :deadline_extended)
  #         .from(false)
  #         .to(true)
  #     end

  #     it 'sets new external_deadline' do
  #       expect { approved_sar.extend_deadline!(new_deadline) }.to \
  #         change(approved_sar, :external_deadline)
  #         .from(initial_deadline)
  #         .to(new_deadline)
  #     end
  #   end

  #   describe '#reset_deadline!' do
  #     let(:extended_sar)      { create(:sar_case, :extended_deadline_sar) }
  #     let(:initial_deadline)  { extended_sar.initial_deadline }
  #     let(:extended_deadline) { extended_sar.external_deadline }

  #     it 'sets #deadline_extended to false' do
  #       expect { extended_sar.reset_deadline! }.to \
  #         change(extended_sar, :deadline_extended)
  #         .from(true)
  #         .to(false)
  #     end

  #     it 'resets external_deadline' do
  #       expect { extended_sar.reset_deadline! }.to \
  #         change(extended_sar, :external_deadline)
  #         .from(extended_deadline)
  #         .to(initial_deadline)
  #     end
  #   end
  # end

  describe '#reassign_gov_uk_dates' do
    let(:kase) { build :offender_sar_case }

    it 'only re-assigns Gov UK date fields that are unchanged' do
      original_dob = kase.date_of_birth
      kase.reassign_gov_uk_dates
      kase.save!

      expect(kase.date_of_birth).to eq original_dob
    end

    it 'does not reassign changed Gov UK dates fields' do
      new_dob = Date.parse('1990-10-01')
      kase.date_of_birth = new_dob
      kase.reassign_gov_uk_dates
      kase.save!

      expect(kase.date_of_birth).to eq new_dob
    end
  end

  describe '#allow_waiting_for_data_state?' do
    it 'is true when the current state is data_to_be_requested only' do
      kase = build :offender_sar_case
      expect(kase.current_state).to eq 'data_to_be_requested'
      expect(kase.allow_waiting_for_data_state?).to be true

      kase.current_state = 'waiting_for_data'
      expect(kase.allow_waiting_for_data_state?).to be false
    end
  end

  describe '#subject_address' do
    it 'validates presence of subject address' do
      kase = build :offender_sar_case, subject_address: ''
      expect(kase).not_to be_valid
      expect(kase.errors[:subject_address]).to eq ["can't be blank"]
    end
  end
end
