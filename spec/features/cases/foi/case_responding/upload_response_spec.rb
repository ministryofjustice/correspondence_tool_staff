require 'rails_helper'

feature 'Upload response' do
  given(:drafter)           { create(:drafter) }
  given(:kase)              { create(:accepted_case, drafter: drafter) }

  background do
    create(:category, :foi)
  end

  context 'as the assigned drafter' do
    background do
      login_as drafter
    end

    scenario 'clicking link on case detail page goes to upload page' do
      cases_show_page.load(id: kase.id)

      click_link 'Upload response'

      expect(current_path).to eq new_response_upload_case_path(kase)
    end
  end

  context "as a drafter that isn't assigned to the case" do
    given(:unassigned_drafter) { create(:drafter) }

    background do
      login_as unassigned_drafter
    end

    scenario "link to case upload page isn't visible on detail page" do
      cases_new_response_upload_page.load(id: kase.id)

      expect(cases_new_response_upload_page).not_to have_link('Upload response')
    end
  end
end
