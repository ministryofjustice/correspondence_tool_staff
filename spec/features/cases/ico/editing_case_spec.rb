require 'rails_helper'

feature 'editing an ICO case' do
  given(:manager) { create :disclosure_bmt_user }

  background do
    login_as manager
  end

  scenario 'changing details', js: true do
    kase = create(:ico_foi_case)
    new_original_case = create(:foi_case)
    new_related_case = create(:timeliness_review)

    cases_show_page.load(id: kase.id)
    expect(cases_show_page).to be_displayed(id: kase.id)
    click_link 'Edit case details'
    expect(cases_edit_page).to be_displayed

    request_attachment = Rails.root.join('spec', 'fixtures', 'new request.docx')
    cases_edit_ico_page.form.fill_in_case_details(
      ico_reference_number: 'IZEDITED',
      ico_officer_name: 'Richie King',
      message: 'Consider this case to be edited',
      uploaded_request_files: [request_attachment]
    )
    cases_edit_ico_page.form.original_case.linked_records.first.remove_link.click
    cases_edit_ico_page.form.add_original_case(new_original_case)
    cases_edit_ico_page.form.add_related_cases([new_related_case])
    click_button 'Submit'
    expect(cases_show_page).to be_displayed(id: kase.id)

    kase.reload
    case_details = cases_show_page.ico.case_details

    expect(case_details.ico_reference.data.text).to eq kase.ico_reference_number
    expect(case_details.ico_officer_name.data.text).to eq kase.ico_officer_name

    date_received = kase.received_date.strftime(Settings.default_date_format)
    expect(case_details.date_received.data.text).to eq date_received

    external_deadline = kase.external_deadline.strftime(Settings.default_date_format)
    expect(case_details.external_deadline.data.text).to eq external_deadline

    expect(cases_show_page.ico.case_details.date_received.data.text)
      .to eq kase.received_date.strftime(Settings.default_date_format)
    expect(cases_show_page.ico.case_details.external_deadline.data.text)
      .to eq kase.external_deadline.strftime(Settings.default_date_format)

    expect(cases_show_page.request.message.text).to eq kase.message

    expect(cases_show_page.ico.original_cases).to have_linked_records(count: 1)
    original_case_link = cases_show_page.ico.original_cases.linked_records.first
    expect(original_case_link.link).to have_text new_original_case.number

    expect(cases_show_page.ico.related_cases).to have_linked_records(count: 1)
    related_case_link = cases_show_page.ico.related_cases.linked_records.first
    expect(related_case_link.link).to have_text new_related_case.number

    expect(cases_show_page.request.attachments.first.collection.first.filename.text)
      .to eq 'new request.docx'
  end

end
