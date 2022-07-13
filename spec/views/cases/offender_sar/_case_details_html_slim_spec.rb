require 'rails_helper'

describe 'cases/sar/case_details.html.slim', type: :view do
  let(:offender_sar_case) {
    (create :offender_sar_case, subject_aliases: 'John Smith',
            date_of_birth: '2019-09-01').decorate
  }

  let(:branston_user)             { find_or_create :branston_user }


  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as branston_user }

  describe 'basic_details' do
    it 'displays the initial case details (non third party case)' do
      assign(:case, offender_sar_case)
      render partial: 'cases/offender_sar/case_details',
             locals: { case_details: offender_sar_case,
                       link_type: nil, allow_editing: true}

      partial = offender_sar_case_details_section(rendered).sar_basic_details

      expect(case_details_section(rendered).section_heading.text).to eq 'Case details'

      expect(partial.case_type).to have_no_sar_trigger
      expect(partial.case_type.data.text).to eq "Offender SAR  "
      expect(partial.date_received.data.text)
          .to eq offender_sar_case.received_date.strftime(Settings.default_date_format)
      expect(partial.external_deadline.data.text)
          .to eq offender_sar_case.external_deadline
      expect(partial.third_party.data.text).to eq 'No'
      expect(partial.prison_number.data.text).to eq '123465'
      expect(partial.subject_aliases.data.text).to eq 'John Smith'
      expect(partial.previous_case_numbers.data.text).to eq '54321'
      expect(partial.other_subject_ids.data.text).to eq 'ABC 123 DEF'
      expect(partial.case_reference_number.data.text).to eq '123 ABC 456'
      expect(partial.subject_address.data.text).to eq '22 Sample Address, Test Lane, Testingington, TE57ST'
      expect(partial.requester_reference.data.text).to eq '456 ABC 123'
      expect(partial.request_dated.data.text).to eq '13 Jul 2010'
      expect(partial.date_of_birth.data.text).to eq '1 Sep 2019'
      expect(partial.request_method.data.text).to eq 'email'
    end

    it 'displays third party details if present' do
      third_party_case = (create :offender_sar_case, :third_party, third_party_name: 'Rick Westor').decorate
      assign(:case, third_party_case)
      render partial: 'cases/offender_sar/case_details', locals: {
        case_details: third_party_case,
        link_type: nil, 
        allow_editing: true
      }
      partial = offender_sar_case_details_section(rendered).sar_basic_details

      expect(partial.third_party.data.text).to eq 'Yes'
      expect(partial.third_party_name.data.text).to eq 'Rick Westor'
      expect(partial.requester_reference.data.text).to eq 'FOOG1234'
      expect(partial.third_party_company_name.data.text).to eq 'Foogle and Sons Solicitors at Law'
    end

    it 'does not display Business unit responsible for late response when case closed' do
      late_closed_case = (
        create :offender_sar_case,
        current_state: 'closed',
        received_date: 40.days.ago,
        date_responded: 1.days.ago,
        external_deadline: 40.days.ago).decorate
      assign(:case, late_closed_case)
      render partial: 'cases/offender_sar/case_details', locals: {
        case_details: late_closed_case,
        link_type: nil,
        allow_editing: true
      }
      partial = offender_sar_case_details_section(rendered).response_details
      expect(partial.has_selector?(".late-team")).to eq false
    end
  end
end
