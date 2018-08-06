require 'rails_helper'

describe 'cases/ico/case_details.html.slim', type: :view do
  let(:ico_foi_case)  { (build_stubbed :ico_foi_case).decorate }
  let(:accepted_case) { (create :accepted_ico_foi_case).decorate }

  describe 'edit case link' do
    before do
      assign(:case, ico_foi_case)
      login_as create(:manager)
      render partial: 'cases/ico/case_details.html.slim',
             locals:{ case_details: ico_foi_case}
    end

    it 'displays edit case link' do
      partial = case_details_section(rendered)
      expect(partial).to have_edit_case_link
    end
  end

  describe 'basic_details' do
    it 'displays the initial case details' do
      assign(:case, ico_foi_case)
      login_as create(:manager)
      render partial: 'cases/ico/case_details.html.slim',
             locals:{ case_details: ico_foi_case}

      partial = case_details_section(rendered).ico_basic_details
      expect(partial.case_type).to have_no_ico_trigger
      expect(partial.ico_reference.data.text).to eq ico_foi_case.ico_reference_number
      expect(partial.ico_officer_name.data.text).to eq ico_foi_case.ico_officer_name
      expect(partial.case_type.data.text).to eq "ICO appeal(FOI)  "
      expect(partial.date_received.data.text)
        .to eq ico_foi_case.received_date.strftime(Settings.default_date_format)
      expect(partial.external_deadline.data.text)
        .to eq ico_foi_case.external_deadline
    end

  end

  describe 'responders details' do
    it 'displays the responders team name' do
      assign(:case, accepted_case)
      login_as create(:manager)
      render partial: 'cases/ico/case_details.html.slim',
             locals:{ case_details: accepted_case}

      partial = case_details_section(rendered).responders_details

      expect(partial).to be_all_there
      expect(partial.team.data.text).to eq accepted_case.responding_team.name
      expect(partial.name.data.text).to eq accepted_case.responder.full_name
    end
  end
end
