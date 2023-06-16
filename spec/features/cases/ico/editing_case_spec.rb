require "rails_helper"

feature "editing an ICO case" do
  given(:manager) { find_or_create :disclosure_bmt_user }
  given(:kase) { create :ico_foi_case }
  given(:new_original_case) { create :foi_case }
  given(:new_related_case) { create :timeliness_review }
  given(:another_related_case) { create :timeliness_review }

  background do
    login_as manager

    edit_case(kase)
  end

  scenario "changing details", js: true do
    request_attachment = Rails.root.join("spec", "fixtures", "new request.docx")
    cases_edit_ico_page.form.fill_in_case_details(
      received_date: Date.new(2018, 0o3, 0o4),
      external_deadline: Date.new(2018, 0o3, 24),
      internal_deadline: Date.new(2018, 0o3, 14),
      ico_reference_number: "IZEDITED",
      ico_officer_name: "Richie King",
      message: "Consider this case to be edited",
      uploaded_request_files: [request_attachment],
    )
    cases_edit_ico_page.form.original_case.linked_records.first.remove_link.click
    cases_edit_ico_page.form.add_original_case(new_original_case)
    cases_edit_ico_page.form.add_related_cases([new_related_case])
    click_button "Save changes"
    expect(cases_show_page).to be_displayed(id: kase.id)

    kase.reload
    case_details = cases_show_page.ico.case_details

    expect(case_details.ico_reference.data.text).to eq "IZEDITED"
    expect(case_details.ico_officer_name.data.text).to eq "Richie King"
    expect(case_details.date_received.data.text).to eq "4 Mar 2018"
    expect(case_details.external_deadline.data.text).to eq "24 Mar 2018"
    expect(case_details.internal_deadline.data.text).to eq "14 Mar 2018"
    expect(cases_show_page.request.message.text).to eq kase.message

    check_case_link(cases_show_page.ico.original_cases, new_original_case.number)
    check_case_link(cases_show_page.ico.related_cases, new_related_case.number)
  end

  scenario "changing original case", js: true do
    change_original_case_link(new_original_case)

    click_button "Save changes"
    expect(cases_show_page).to be_displayed(id: kase.id)
    kase.reload

    check_case_link(cases_show_page.ico.original_cases, new_original_case.number)
    check_linked_case_has_relevant_linkage(cases_show_page.ico.original_cases, kase, new_original_case)
  end

  scenario "adding related case", js: true do
    add_related_case_link(new_related_case)

    click_button "Save changes"
    expect(cases_show_page).to be_displayed(id: kase.id)
    kase.reload

    check_case_link(cases_show_page.ico.related_cases, new_related_case.number)
    check_linked_case_has_relevant_linkage(cases_show_page.ico.related_cases, kase, new_related_case)
  end

  scenario "changing related case", js: true do
    add_related_case_link(new_related_case)

    click_button "Save changes"
    expect(cases_show_page).to be_displayed(id: kase.id)
    kase.reload

    edit_case(kase)
    remove_related_case_link
    add_related_case_link(another_related_case)
    click_button "Save changes"
    expect(cases_show_page).to be_displayed(id: kase.id)
    kase.reload

    check_case_link(cases_show_page.ico.related_cases, another_related_case.number)
    check_linked_case_has_relevant_linkage(cases_show_page.ico.related_cases, kase, another_related_case)
  end

private

  def edit_case(kase)
    cases_show_page.load(id: kase.id)
    expect(cases_show_page).to be_displayed(id: kase.id)
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed
  end

  def change_original_case_link(new_original_case)
    cases_edit_ico_page.form.original_case.linked_records.first.remove_link.click
    cases_edit_ico_page.form.add_original_case(new_original_case)
  end

  def add_related_case_link(new_related_case)
    cases_edit_ico_page.form.add_related_cases([new_related_case])
  end

  def remove_related_case_link
    cases_edit_ico_page.form.related_cases.linked_records.first.remove_link.click
  end

  def check_case_link(case_link, case_number)
    expect(case_link).to have_linked_records(count: 1)
    case_link_element = case_link.linked_records.first
    expect(case_link_element.link).to have_text case_number
  end

  def check_linked_case_has_relevant_linkage(case_link, kase, linked_case)
    case_link.linked_records.first.link.click
    expect(cases_show_page).to be_displayed(id: linked_case.id)

    related_case_link = cases_show_page.link_case.linked_records.first
    expect(related_case_link.link).to have_text kase.number
  end
end
