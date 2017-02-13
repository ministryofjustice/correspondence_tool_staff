require 'rails_helper'

feature 'Upload response' do
  given(:case_upload_page)  { CaseUploadPage.new }
  given(:case_details_page) { CaseDetailsPage.new }
  given(:drafter)           { create(:drafter) }
  given(:kase)              { create(:accepted_case, drafter: drafter) }
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
      case_details_page.load(id: kase.id)

      click_link 'Upload response'

      expect(current_path).to eq new_response_upload_case_path(kase)
    end

    scenario 'removing previously uploaded files' do
      case_details_page.load(id: kase.id)

      case_details_page.uploaded_files.first.remove.click
      expect(case_details_page.uploaded_files).to be_empty
    end
  end

  context "as a drafter that isn't assigned to the case" do
    given(:unassigned_drafter) { create(:drafter) }

    background do
      login_as unassigned_drafter
    end

    scenario "link to case upload page isn't visible on detail page" do
      case_upload_page.load(id: kase.id)

      expect(case_upload_page).not_to have_link('Upload response')
    end
  end
end
