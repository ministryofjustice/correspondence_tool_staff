require 'rails_helper'

feature 'Upload response' do
  given(:page) { CaseUploadPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase) do
    create(:accepted_case, assignee: drafter)
  end
  given(:attachment_1) do
    create(:correspondence_response, case: kase)
  end

  background do
    create(:category, :foi)
    attachment_1
    login_as drafter
  end

  scenario 'viewing uploaded files' do
    visit new_response_upload_case_path kase

    attachment_filename = File.basename(
      URI.parse(attachment_1.url).path
    )
    expect(page.existing_files).to have_content(attachment_filename)
  end
end
