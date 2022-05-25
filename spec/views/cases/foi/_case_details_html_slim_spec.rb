require 'rails_helper'

describe 'cases/foi/case_details.html.slim', type: :view do
  let(:unassigned_case)         { create(:case).decorate }
  let(:accepted_case)           { create(:accepted_case).decorate }
  let(:approved_case)          { create(:approved_case).decorate }
  let(:trigger_case)            { create(:case, :flagged_accepted).decorate }

  let(:closed_case)             { create(:closed_case).decorate }
  let(:disclosure_specialist)   { find_or_create :disclosure_specialist }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end


  before(:each) { login_as disclosure_specialist }



  describe 'foi_basic_details' do
    it 'displays the initial case details' do
      assign(:case, unassigned_case)
      render partial: 'cases/foi/case_details',
             locals: { case_details: unassigned_case,
                       link_type: nil }

      partial = case_details_section(rendered).foi_basic_details

      expect(case_details_section(rendered).section_heading.text).to eq 'Case details'

      expect(partial).to be_all_there

      expect(partial.case_type).to have_no_foi_trigger

      expect(partial.case_type.data.text).to eq "FOI  "

      expect(partial.date_received.data.text)
          .to eq unassigned_case.received_date.strftime(Settings.default_date_format)

      expect(partial.name.data.text)
          .to eq unassigned_case.name

      expect(partial.email.data.text)
          .to eq unassigned_case.email

      expect(partial.address.data.text)
          .to eq unassigned_case.postal_address

      expect(partial.requester_type.data.text)
          .to eq unassigned_case.requester_type.humanize

      expect(partial.delivery_method.data.text)
          .to eq unassigned_case.delivery_method.humanize

    end

    it 'displays a trigger badge if the case has been triggered' do
      trigger_case
      assign(:case, trigger_case)
      render partial: 'cases/foi/case_details',
             locals: { case_details: trigger_case,
                       link_type: nil }

      partial = case_details_section(rendered).foi_basic_details

      expect(partial).to be_all_there

      expect(partial.case_type).to have_foi_trigger

      expect(partial.case_type.data.text).to eq "FOI This is a Trigger case"
    end

    it 'does not display the email address if one is not provided' do
      unassigned_case.email = nil
      assign(:case, unassigned_case)
      render partial: 'cases/foi/case_details',
             locals: { case_details: unassigned_case,
                       link_type: nil }

      partial = case_details_section(rendered).foi_basic_details

      expect(partial).to have_no_email
      expect(partial).to have_address
    end

    it 'does not display the postal address if one is not provided' do
      unassigned_case.postal_address = nil
      assign(:case, unassigned_case)
      render partial: 'cases/foi/case_details',
             locals: { case_details: unassigned_case,
                       link_type: nil }

      partial = case_details_section(rendered).foi_basic_details

      expect(partial).to have_no_address
      expect(partial).to have_email
    end
  end

  describe 'responders details' do
    it 'displays the responders team name' do
      assign(:case, accepted_case)
      render partial: 'cases/foi/case_details',
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
      render partial: 'cases/foi/case_details',
             locals:{ case_details: approved_case,
                      link_type: nil }

      partial = case_details_section(rendered).compliance_details

      expect(partial.compliance_date.data.text).to eq approved_case.date_draft_compliant
      expect(partial.compliant_timeliness.data.text).to eq approved_case.draft_timeliness
    end
  end

  describe 'Final response details' do

    it 'displays all the case closure details' do
      closed_case
      assign(:case, closed_case)
      render partial: 'cases/foi/case_details',
             locals: { case_details: closed_case,
                       link_type: nil }

      partial = case_details_section(rendered).response_details
      expect(partial.date_responded.data.text).to eq closed_case.date_sent_to_requester
      expect(partial.timeliness.data.text).to eq closed_case.timeliness
      expect(partial.outcome.data.text).to eq closed_case.outcome.name
    end

  end

  describe 'original case details' do
    let(:ico_case) { create :ico_foi_case}

    it 'displays as original case' do
      assign(:case, ico_case)
      render partial: 'cases/foi/case_details',
             locals:{ case_details: ico_case.original_case.decorate,
                      link_type: 'original' }

      partial = case_details_section(rendered)
      expect(partial.original_section_heading.text).to eq "Original case details"
    end

    it 'displays a link to original case' do
      assign(:case, ico_case)
      render partial: 'cases/foi/case_details',
             locals:{ case_details: ico_case.original_case.decorate,
                      link_type: 'original' }

      partial = case_details_section(rendered)
      expect(partial).to have_view_original_case_link
    end

  end
end
