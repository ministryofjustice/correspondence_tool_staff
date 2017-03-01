require 'rails_helper'

feature 'uploaded files on case details view' do
  given(:case_details_page) { CaseDetailsPage.new }
  given(:drafter) { create(:drafter) }
  given(:kase)    { create(:accepted_case, drafter: drafter) }
  background do
    login_as user
  end

  context 'as the assigned drafter' do
    given(:user) { drafter }

    context 'with an attached response' do
      given(:attached_response) do
        create(:case_response, case: kase)
      end
      given(:attachment_url) do
        URI.encode("#{CASE_UPLOADS_S3_BUCKET.url}/#{attached_response.key}")
      end
      given(:attachment_object) do
        instance_double(
          Aws::S3::Object,
          delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
          public_url: attachment_url
        )
      end

      background do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.key)
                                           .and_return(attachment_object)
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
        }.to redirect_to_external(attachment_url)
      end

      scenario 'can remove the response' do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        expect(case_details_page).not_to have_uploaded_files
        expect(attachment_object).to have_received(:delete)
        expect(current_path).to eq case_path(kase)
      end

      scenario 'removes the section from the page' do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        case_details_page.wait_until_uploaded_files_invisible
        expect(case_details_page).not_to have_uploaded_files
      end

      scenario 'can remove the response with JS', js: true do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        case_details_page.wait_until_uploaded_files_invisible
        expect(case_details_page).not_to have_uploaded_files
        expect(attachment_object).to have_received(:delete)
      end

      scenario 'removes the section from the page with JS', js: true do
        case_details_page.load(id: kase.id)

        case_details_page.uploaded_files.files.first.remove.click
        case_details_page.wait_until_uploaded_files_invisible
        expect(case_details_page).not_to have_uploaded_files
      end

      context 'case has multiple attachments' do
        before do
          create :case_response, case: kase
        end

        scenario 'uploaded files section is not removed' do
          case_details_page.load(id: kase.id)

          case_details_page.uploaded_files.files.first.remove.click
          expect(case_details_page).to have_uploaded_files
          expect(case_details_page.uploaded_files.files.count).to eq 1
        end

        scenario 'uploaded files section is not removed', js: true do
          case_details_page.load(id: kase.id)

          case_details_page.uploaded_files.files.first.remove.click
          case_details_page.uploaded_files.wait_for_files count: 1
        end
      end
    end

    context 'with no attached responses' do
      scenario 'is not visible' do
        case_details_page.load(id: kase.id)

        expect(case_details_page).not_to have_uploaded_files
      end
    end
  end
end
