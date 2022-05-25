require 'rails_helper'

describe 'cases/sar/case_details.html.slim', type: :view do
  let(:unassigned_case)         { (create :sar_case).decorate }
  let(:accepted_case)           { (create :accepted_sar).decorate }
  let(:approved_case)           { (create :approved_sar).decorate}
  let(:bmt_manager)             { find_or_create :disclosure_bmt_user }


  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end

  before(:each) { login_as bmt_manager }

  describe 'basic_details' do
    it 'displays the initial case details (non third party case' do
      assign(:case, unassigned_case)
      render partial: 'cases/sar/case_details',
             locals: { case_details: unassigned_case,
                       link_type: nil }

      partial = case_details_section(rendered).sar_basic_details

      expect(case_details_section(rendered).section_heading.text).to eq 'Case details'

      expect(partial.case_type).to have_no_sar_trigger
      expect(partial.case_type.data.text).to eq "SAR  "
      expect(partial.date_received.data.text)
          .to eq unassigned_case.received_date.strftime(Settings.default_date_format)
      expect(partial.external_deadline.data.text)
          .to eq unassigned_case.external_deadline
      expect(partial.third_party.data.text).to eq 'No'
    end

    it 'displays third party details if present' do
      third_party_case = (create :sar_case, :third_party, name: 'Rick Westor').decorate
      assign(:case, third_party_case)
      render partial: 'cases/sar/case_details',
             locals: { case_details: third_party_case,
                       link_type: nil }
      partial = case_details_section(rendered).sar_basic_details
      expect(partial.third_party.data.text).to eq 'Yes'
      expect(partial.requester_name.data.text).to eq 'Rick Westor'

    end

    it 'does not display the email address if one is not provided' do
      unassigned_case.email = nil
      unassigned_case.postal_address = "1 High Street\nAnytown\nAT1 1AA"
      unassigned_case.reply_method = 'send_by_post'

      assign(:case, unassigned_case)
      render partial: 'cases/sar/case_details',
             locals: { case_details: unassigned_case,
                       link_type: nil }

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq "1 High Street\nAnytown\nAT1 1AA"
    end

    it 'does not display the postal address if one is not provided' do
      unassigned_case.postal_address = nil
      unassigned_case.email = 'john.doe@moj.com'

      assign(:case, unassigned_case)
      render partial: 'cases/sar/case_details',
             locals:{ case_details: unassigned_case,
                      link_type: nil }

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq 'john.doe@moj.com'
    end
  end

  describe 'responders details' do
    it 'displays the responders team name' do
      assign(:case, accepted_case)
      render partial: 'cases/sar/case_details',
             locals:{ case_details: accepted_case,
                      link_type: nil }

      partial = case_details_section(rendered).responders_details

      expect(partial).to be_all_there
      expect(partial.team.data.text).to eq accepted_case.responding_team.name
      expect(partial.name.data.text).to eq accepted_case.responder.full_name
    end
  end

  describe 'draft compliance details' do
    it 'displays the date compliant' do
      assign(:case, approved_case)

      render partial: 'cases/sar/case_details',
             locals:{ case_details: approved_case,
                      link_type: nil }

      partial = case_details_section(rendered).compliance_details

      expect(partial.compliance_date.data.text).to eq approved_case.date_draft_compliant
      expect(partial.compliant_timeliness.data.text).to eq approved_case.draft_timeliness
    end
  end


  describe 'original case details' do
    let(:ico_case) { create :ico_sar_case}

    it 'displays as original case' do
      assign(:case, ico_case)
      render partial: 'cases/sar/case_details',
             locals: { case_details: ico_case.original_case.decorate,
                       link_type: 'original' }

      partial = case_details_section(rendered)
      expect(partial.original_section_heading.text).to eq "Original case details"
    end

    it 'displays a link to original case' do
      assign(:case, ico_case)
      render partial: 'cases/sar/case_details',
             locals: { case_details: ico_case.original_case.decorate,
                       link_type: nil }

      partial = case_details_section(rendered)
      expect(partial).to have_view_original_case_link
    end

  end


end
