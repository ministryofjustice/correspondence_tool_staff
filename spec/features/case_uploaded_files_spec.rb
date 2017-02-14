require 'rails_helper'

feature 'uploaded files on case details view' do
  given(:case_details_page) { CaseDetailsPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase)    { create(:accepted_case, drafter: drafter) }
  given(:attachment_1) do
    create(:correspondence_response, case: kase)
  end

  background do
    login_as user

    # create(:category, :foi)
    attachment_1
  end

  context 'as the assigned drafter' do
    given(:user) { drafter }

    scenario 'can be listed' do
      case_details_page.load(id: kase.id)

      expect(case_details_page.uploaded_files.first.filename)
        .to have_content(attachment_1.filename)
    end
  end
end
