require 'rails_helper'

feature 'Upload response' do
  given(:page)    { CaseUploadPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase)    { create(:accepted_case, drafter: drafter) }
  given(:attachment_1) do
    create(:correspondence_response, case: kase)
  end

  background do
    create(:category, :foi)
    attachment_1
  end

  context 'as the assigned drafter' do
    background do
      login_as drafter
    end

    scenario 'clicking link on case detail page goes to upload page' do
      visit case_path(kase)

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
      visit case_path(kase)

      expect(page).not_to have_link('Upload response')
    end
  end
end
