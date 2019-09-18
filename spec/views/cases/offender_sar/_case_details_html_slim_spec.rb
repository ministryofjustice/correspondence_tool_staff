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
      render partial: 'cases/offender_sar/case_details.html.slim',
             locals: { case_details: offender_sar_case,
                       link_type: nil }

      partial = offender_sar_case_details_section(rendered).sar_basic_details
      expect(case_details_section(rendered).section_heading.text).to eq 'Case details'

      expect(partial.case_type).to have_no_sar_trigger
      expect(partial.case_type.data.text).to eq "OFFENDER-SAR  "
      expect(partial.date_received.data.text)
          .to eq offender_sar_case.received_date.strftime(Settings.default_date_format)
      expect(partial.external_deadline.data.text)
          .to eq offender_sar_case.external_deadline
      expect(partial.third_party.data.text).to eq 'No'
      expect(partial.prison_number.data.text).to eq '123465'

      expect(partial.subject_aliases.data.text).to eq 'John Smith'
      expect(partial.previous_case_numbers.data.text).to eq '54321'
      expect(partial.other_subject_ids.data.text).to eq 'ABC 123 DEF'
      expect(partial.date_of_birth.data.text).to eq '1 Sep 2019'
    end

    it 'displays third party details if present' do
      third_party_case = (create :sar_case, :third_party, name: 'Rick Westor').decorate
      assign(:case, third_party_case)
      render partial: 'cases/sar/case_details.html.slim', locals: {
        case_details: third_party_case,
        link_type: nil
      }
      partial = case_details_section(rendered).sar_basic_details
      expect(partial.third_party.data.text).to eq 'Yes'
      expect(partial.requester_name.data.text).to eq 'Rick Westor'
    end

    it 'does not display the email address if one is not provided' do
      offender_sar_case.email = nil
      offender_sar_case.postal_address = "1 High Street\nAnytown\nAT1 1AA"
      offender_sar_case.reply_method = 'send_by_post'

      assign(:case, offender_sar_case)
      render partial: 'cases/sar/case_details.html.slim',
             locals: { case_details: offender_sar_case,
                       link_type: nil }

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq "1 High Street\nAnytown\nAT1 1AA"
    end

    it 'does not display the postal address if one is not provided' do
      offender_sar_case.postal_address = nil
      offender_sar_case.email = 'john.doe@moj.com'

      assign(:case, offender_sar_case)
      render partial: 'cases/sar/case_details.html.slim',
             locals:{ case_details: offender_sar_case,
                      link_type: nil }

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq 'john.doe@moj.com'
    end
  end
end
