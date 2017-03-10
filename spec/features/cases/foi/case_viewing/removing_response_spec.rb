require 'rails_helper'

feature 'removing a response from response details' do
  given(:drafter)  { create(:drafter) }
  given(:assigner) { create(:assigner) }

  context 'as the assigned drafter' do
    background do
      login_as drafter
    end

    context 'with a case that is still in drafting' do
      given(:case_with_response) do
        create :case_with_response, drafter: drafter
      end
      given(:attached_response) do
        case_with_response.attachments.response.first
      end
      given(:attachment_object) do
        instance_double(
          Aws::S3::Object,
          delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
        )
      end
      given(:uploaded_file) do
        cases_show_page.response_details.responses.first
      end

      background do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.key)
                                           .and_return(attachment_object)
      end

      context 'when there is only one response' do
        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)
          uploaded_file.remove.click

          expect(cases_show_page).not_to have_response_details
          expect(attachment_object).to have_received(:delete)
          expect(current_path).to eq case_path(case_with_response)
        end

        scenario 'when removing the response with JS', js: true do
          cases_show_page.load(id: case_with_response.id)

          expect(uploaded_file.remove['data-confirm'])
            .to eq "Are you sure you want to remove #{attached_response.filename}?"
          uploaded_file.remove.click

          cases_show_page.wait_until_response_details_invisible
          expect(cases_show_page).not_to have_response_details
          expect(attachment_object).to have_received(:delete)
          expect(cases_show_page.sidebar.actions).not_to have_mark_as_sent
        end
      end

      context 'when there are multiple responses' do
        background do
          other_response = create :case_response, case: case_with_response
          allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                             .with(other_response.key)
                                             .and_return(double(delete: nil))
        end

        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)

          cases_show_page.response_details.responses.first.remove.click
          expect(cases_show_page).to have_response_details
        end

        scenario 'when removing the response with JS', js: true do
          cases_show_page.load(id: case_with_response.id)

          expect(cases_show_page.response_details.responses.count).to eq 2
          uploaded_file.remove.click
          cases_show_page.response_details.wait_for_responses nil, count: 1
          expect(cases_show_page.response_details.responses.count)
            .to eq 1
        end
      end
    end

    context 'with a case marked as sent' do
      given(:responded_case) do
        create(:responded_case, drafter: drafter)
      end

      scenario 'is not visible' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page).not_to have_response_details
      end
    end
  end

  context 'as an assigner' do
    background do
      login_as assigner
    end

    context 'with a case marked as sent' do
      given(:responded_case) do
        create(:responded_case, drafter: drafter)
      end

      scenario 'does not display remove button' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page.response_details.responses.first)
          .not_to have_remove
      end
    end

  end
end
