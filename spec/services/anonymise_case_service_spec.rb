require 'rails_helper'

describe RetentionSchedules::AnonymiseCaseService do
  # let(:manager)         { find_or_create :branston_user }
  # let(:managing_team)   { create :managing_team, managers: [manager] }

  let!(:offender_sar_case) { 
    case_with_retention_schedule(
      case_type: :offender_sar_case, 
      case_state: :closed,
      rs_state: 'to_be_destroyed',
      date: Date.today - 4.months
    ) 
  }

  let!(:offender_sar_complaint) { 
    case_with_retention_schedule(
      case_type: :offender_sar_complaint, 
      case_state: :closed,
      rs_state: 'to_be_destroyed',
      date: Date.today - 4.months
    ) 
  }

  let(:service) {
    RetentionSchedules::AnonymiseCaseService.new(kase: offender_sar_case)
  }

  let(:service_two) {
    RetentionSchedules::AnonymiseCaseService.new(kase: offender_sar_complaint)
  }

  let(:expected_off_sar_anon_values) do
    {
      case_reference_number: 'XXXX XXXX',
      date_of_birth: Date.new(01, 01, 0001),
      email: 'anon@email.com',
      message: 'XXXX XXXX',
      name: 'XXXX XXXX',
      postal_address: 'XXXX XXXX',
      previous_case_numbers: 'XXXX XXXX',
      prison_number: 'XXXX XXXX',
      requester_reference: 'XXXX XXXX',
      subject: 'XXXX XXXX',
      subject_address: 'XXXX XXXX',
      subject_aliases: 'XXXX XXXX',
      subject_full_name: 'XXXX XXXX',
      third_party_company_name: 'XXXX XXXX',
      third_party_name: 'XXXX XXXX',
    }
  end

  let(:expected_off_sar_complaint_anon_values) do
    expected_off_sar_anon_values.merge(
      {
        gld_contact_email: 'XXXX XXXX',
        gld_contact_name: 'XXXX XXXX',
        gld_contact_phone: 'XXXX XXXX',
        gld_reference: 'XXXX XXXX',
        ico_contact_email: 'XXXX XXXX',
        ico_contact_name: 'XXXX XXXX',
        ico_contact_phone: 'XXXX XXXX',
        ico_reference: 'XXXX XXXX',
      }
    )
  end


  describe '#call' do
    before do
      service.call
      service_two.call
      offender_sar_case.reload
      offender_sar_complaint.reload
    end

    it 'can anonymise the key fields of a case Offender SAR case' do
      expected_off_sar_anon_values.each do |kase_attribute_name, value|
        # puts "#{kase_attribute_name} -> #{offender_sar_case.send(kase_attribute_name)} : #{value}"
        expect(offender_sar_case.send(kase_attribute_name)).to eq(value)
      end
    end

    it 'can anonymise the key fields of a case Offender SAR Complaint case' do
      expected_off_sar_complaint_anon_values.each do |kase_attribute_name, value|
        # puts "#{kase_attribute_name} -> #{offender_sar_case.send(kase_attribute_name)} : #{value}"
        expect(offender_sar_complaint.send(kase_attribute_name)).to eq(value)
      end
    end

    xit 'can anonymise the notes on a case' do
    end

    xit 'can anonymise the papertrail versions of a case' do
    end

    xit 'can anonymise the data request other details of a case' do
    end
  end

  describe 'error states' do
    before do
      service.call
    end

    xit 'will raise an error if cases is not closed' do
    end

    xit 'will raise an error if cases has no retention schedule' do
    end

    xit 'will raise and error if a case is not and Offender SAR or an Offender SAR complaint' do
    end

    xit 'will raise an error if the cases retention schedule does not have a state of :to_be_destroyed' do
    end
  end

  def case_with_retention_schedule(case_type:, case_state:, rs_state:, date:)
    kase = create(
      case_type, 
      retention_schedule: 
        RetentionSchedule.new( 
         state: rs_state,
         planned_destruction_date: date 
      ) 
    )
    kase.save
    kase
  end
end
