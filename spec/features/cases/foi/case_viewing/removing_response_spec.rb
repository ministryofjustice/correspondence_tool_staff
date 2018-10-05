require 'rails_helper'

feature 'removing a response from response details' do
  given(:responder) { create(:responder) }
  given(:manager)   { create(:manager) }
  given(:responder_teammate) do
    create :responder,
           responding_teams: responder.responding_teams
  end

  given(:case_with_response) do
    create :case_with_response, responder: responder
  end
  given!(:attached_response) do
    case_with_response.attachments.response.first
  end
  given(:attachment_object) do
    instance_double(
      Aws::S3::Object,
      delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
    )
  end
  given(:preview_object) do
    instance_double(
      Aws::S3::Object,
      delete: instance_double(Aws::S3::Types::DeleteObjectOutput),
    )
  end
  given(:uploaded_file) do
    cases_show_page.case_attachments.first.collection
  end

  given(:approved_case ) { create(:approved_case, responder: responder) }

  context 'as the assigned responder' do
    background do
      login_as responder
    end

    context 'with a case that is still in drafting' do
      background do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.key)
                                           .and_return(attachment_object)
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.preview_key)
                                           .and_return(preview_object)
      end

      context 'when there is only one response' do
        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)

          uploaded_file.first.actions.remove.click

          expect(cases_show_page).to have_no_case_attachments
          expect(attachment_object).to have_received(:delete)
          expect(current_path).to eq case_path(case_with_response)
        end

        scenario 'when removing the response with JS', js: true do
          cases_show_page.load(id: case_with_response.id)

          expect(uploaded_file.first.actions.remove['data-confirm'])
            .to eq "Are you sure you want to remove #{attached_response.filename}?"
          accept_alert do
            uploaded_file.first.actions.remove.click
          end
          sleep 0.25
          cases_show_page.wait_until_case_attachments_visible nil, count: 0
          expect(cases_show_page).to have_no_case_attachments
          expect(attachment_object).to have_received(:delete)
        end
      end

      context 'when there are multiple responses' do
        before do
          other_response = create :case_response, case: case_with_response, user_id: responder.id
          allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                             .with(other_response.key)
                                             .and_return(double(delete: nil))
          allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                             .with(other_response.preview_key)
                                             .and_return(double(delete: nil))
        end

        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)
          cases_show_page.case_attachments.first.collection.first.actions.remove.click
          expect(cases_show_page).to have_case_attachments
        end

        #  TODO  fix this flickering test
        # scenario 'when removing the response with JS', js: true do
        #   cases_show_page.load(id: case_with_response.id)
        #   cases_show_page.wait_for_case_attachments nil, count: 2
        #   cases_show_page.case_attachments.first.wait_for_collection 10, count: 2
        #   expect(uploaded_file.count).to eq 2
        #   uploaded_file.first.actions.remove.click
        #   cases_show_page.wait_for_case_attachments nil, count: 1
        #
        #   expect(cases_show_page.case_attachments.count).to eq 1
        # end
      end
    end

    context 'with a case marked as sent' do
      given(:responded_case) do
        create(:responded_case, responder: responder)
      end

      scenario 'does not display remove button' do
        cases_show_page.load(id: responded_case.id)
        expect(cases_show_page.case_attachments.first.collection.first.actions)
            .to have_no_remove
      end
    end

    context 'approved case' do
      scenario 'viewing case should not show remove upload link' do
        cases_show_page.load(id: approved_case.id)
        expect(cases_show_page.case_attachments.first.collection.first.actions)
            .to have_no_remove
      end
    end
  end

  context 'as a responder on the same team' do
    background do
      login_as responder_teammate
    end

    context 'with a case that is still in drafting' do
      background do
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.key)
                                           .and_return(attachment_object)
        allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                           .with(attached_response.preview_key)
                                           .and_return(preview_object)
      end

      context 'when there is only one response' do
        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)
          uploaded_file.first.actions.remove.click

          expect(cases_show_page).to have_no_case_attachments
          expect(attachment_object).to have_received(:delete)
          expect(current_path).to eq case_path(case_with_response)
        end

        scenario 'when removing the response with JS', js: true do
          cases_show_page.load(id: case_with_response.id)

          expect(uploaded_file.first.actions.remove['data-confirm'])
            .to eq "Are you sure you want to remove #{attached_response.filename}?"
          accept_alert do
            uploaded_file.first.actions.remove.click
          end
          cases_show_page.wait_until_case_attachments_visible 10, count: 0
          expect(cases_show_page).to have_no_case_attachments
          expect(attachment_object).to have_received(:delete)
          expect(cases_show_page.actions).to have_no_mark_as_sent
        end
      end

      context 'when there are multiple responses' do
        background do
          other_response = create :case_response, case: case_with_response, user_id: responder.id
          allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                             .with(other_response.key)
                                             .and_return(double(delete: nil))
          allow(CASE_UPLOADS_S3_BUCKET).to receive(:object)
                                             .with(other_response.preview_key)
                                             .and_return(double(delete: nil))

        end

        scenario 'when removing the response' do
          cases_show_page.load(id: case_with_response.id)

          cases_show_page.case_attachments.first.collection.first.actions.remove.click
          expect(cases_show_page).to have_case_attachments
        end

        # TODO work out how to fix this flickering test

        # scenario 'when removing the response with JS', js: true do
        #   cases_show_page.load(id: case_with_response.id)
        #   cases_show_page.wait_for_case_attachments 4, count: 2
        #   cases_show_page.case_attachments.first.wait_for_collection 10, count: 2
        #   expect(cases_show_page.case_attachments.first.collection.count).to eq 2
        #   uploaded_file.first.actions.remove.click
        #   cases_show_page.wait_for_case_attachments nil, count: 1
        #   expect(cases_show_page.case_attachments.count)
        #     .to eq 1
        # end
      end
    end

    context 'with a case marked as sent' do
      given(:responded_case) do
        create(:responded_case, responder: responder)
      end

      scenario 'does not display remove button' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page.case_attachments.first.collection.first.actions)
            .to have_no_remove
      end
    end
  end

  context 'as an manager' do
    background do
      login_as manager
    end

    context 'with a case marked as sent' do
      given(:responded_case) do
        create(:responded_case, responder: responder)
      end

      scenario 'does not display remove button' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page.case_attachments.first.collection.first.actions)
          .to have_no_remove
      end
    end

  end
end
