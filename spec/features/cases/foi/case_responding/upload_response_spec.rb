require 'rails_helper'

feature 'Upload response' do
  given(:responder)  { create(:responder) }
  given(:kase)       { create(:accepted_case, responder: responder) }
  given(:responder_teammate) do
    create :responder,
           responding_teams: responder.responding_teams
  end

  background do
    create(:category, :foi)
  end

  context 'as the assigned responder' do
    background do
      login_as responder
    end

    scenario 'clicking link on case detail page goes to upload page' do
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).to have_upload_response
      expect(cases_show_page.actions).not_to have_mark_as_sent
      expect(cases_show_page.actions).not_to have_close_case

      click_link 'Upload response'

      expect(current_path).to eq new_response_upload_case_path(kase)
    end
  end

  context 'as a responder on the same team' do
    background do
      login_as responder_teammate
    end

    scenario 'clicking link on case detail page goes to upload page' do
      cases_show_page.load(id: kase.id)
      expect(cases_show_page.actions).to have_upload_response
      expect(cases_show_page.actions).not_to have_mark_as_sent
      expect(cases_show_page.actions).not_to have_close_case

      click_link 'Upload response'

      expect(current_path).to eq new_response_upload_case_path(kase)
    end
  end

  context "as a responder that isn't assigned to the case" do
    given(:unassigned_responder) { create(:responder) }

    background do
      login_as unassigned_responder
    end

    scenario "link to case upload page isn't visible on detail page" do
      cases_new_response_upload_page.load(id: kase.id)

      expect(cases_new_response_upload_page).not_to have_link('Upload response')
    end
  end
end
