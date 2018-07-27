require "rails_helper"

feature 'viewing SAR cases' do
  given(:approver)          { create :approver }
  given(:manager)           { create :disclosure_bmt_user }
  given(:responder)         { create :responder }
  given(:another_responder) { create :responder }

  context 'unassigned case' do
    given!(:kase)   { create :sar_case }

    scenario 'viewing as a manager' do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as a responder' do
      login_as responder

      cases_show_page.load id: kase.id
      expect(open_cases_page).to be_displayed
    end
  end

  context 'assigned case' do
    given!(:kase) { create :accepted_sar, responder: responder }

    scenario 'viewing as a manager' do
      login_as manager

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as assigned responder' do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page).to be_displayed(id: kase.id)
    end

    scenario 'viewing as another responder' do
      login_as another_responder

      cases_show_page.load id: kase.id

      expect(open_cases_page).to be_displayed
    end
  end

  context 'case with both full case details and attachment' do
    given(:request_file) { "#{Faker::Internet.slug}.pdf" }
    given(:kase) do
      create :accepted_sar,
             responder: responder,
             uploading_user: manager,
             uploaded_request_files: [request_file]
    end

    scenario 'displaying case details' do
      login_as responder

      cases_show_page.load id: kase.id

      expect(cases_show_page.request).to have_message
      expect(cases_show_page.request.message.text)
        .to eq kase.message
      expect(cases_show_page.request).to have_attachments
      expect(cases_show_page.request.attachments.count).to eq 1
      expect(cases_show_page.request.attachments[0].collection[0].filename.text)
        .to eq request_file
    end
  end

end
