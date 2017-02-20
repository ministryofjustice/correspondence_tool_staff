require 'rails_helper'

feature 'uploaded files on case details view' do
  given(:case_details_page) { CaseDetailsPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase)    { create(:accepted_case, drafter: drafter) }
  given(:attached_response) do
    create(:case_response, case: kase)
  end

  background do
    login_as user
  end

  context 'as the assigned drafter' do
    given(:user) { drafter }

    context 'with an attached response' do
      background do
        attached_response
      end

      scenario 'can be listed' do
        case_details_page.load(id: kase.id)

        expect(case_details_page).to have_uploaded_files
        expect(case_details_page.uploaded_files.files.first.filename)
          .to have_content(attached_response.filename)
      end

      scenario 'can be downloaded' do
        case_details_page.load(id: kase.id)

        expect {
          case_details_page.uploaded_files.files.first.download.click
        }.to redirect_to_external(attached_response.url)
      end
    end

    context 'with no attached responsed' do
      scenario 'is not visible' do
        case_details_page.load(id: kase.id)

        expect(case_details_page).not_to have_uploaded_files
      end
    end
  end
end
