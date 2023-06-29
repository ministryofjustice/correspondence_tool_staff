def create_foi_case_step(type: "standard",
                         delivery_method: :sent_by_email,
                         uploaded_request_files: [],
                         flag_for_disclosure: false)

  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click

  expect(cases_new_page).to be_displayed

  cases_new_page.create_link_for_correspondence("FOI").click
  expect(cases_new_foi_page).to be_displayed

  # cases_new_foi_page.fill_in_case_type(type)
  cases_new_foi_page.fill_in_case_details(
    type:,
    delivery_method:,
    uploaded_request_files:,
  )
  cases_new_foi_page.choose_flag_for_disclosure_specialists(
    flag_for_disclosure ? "yes" : "no",
  )
  click_button "Create case"

  # Return the case we created using the params of the current  path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  Case::Base.find(kase_id)
end

def create_foi_case_auto_flagged_step(type: "standard",
                                      delivery_method: :sent_by_email,
                                      uploaded_request_files: [])

  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click

  expect(cases_new_page).to be_displayed

  cases_new_page.create_link_for_correspondence("FOI").click
  expect(cases_new_foi_page).to be_displayed

  2.times do
    cases_new_foi_page.fill_in_case_details(
      type: "standard",
      delivery_method:,
      uploaded_request_files:,
    )
    expect(cases_new_foi_page).to have_content("Flag for disclosure specialists")

    cases_new_foi_page.fill_in_case_details(
      type:,
      delivery_method:,
      uploaded_request_files:,
      flag_for_disclosure_specialists: false,
    )

    expect(cases_new_foi_page).not_to have_content("Flag for disclosure specialists")
  end

  click_button "Create case"

  # Return the case we created using the params of the current  path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  Case::Base.find(kase_id)
end

def create_ico_case_step(original_case:, related_cases: [], uploaded_request_files: [])
  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click

  expect(cases_new_page).to be_displayed

  cases_new_page.create_link_for_correspondence("ICO").click
  expect(cases_new_ico_page).to be_displayed

  cases_new_ico_page.form.fill_in_case_details(
    uploaded_request_files:,
  )
  cases_new_ico_page.form.add_original_case(original_case)
  cases_new_ico_page.form.add_related_cases(related_cases)

  click_button "Create case"

  expect(assignments_new_page).to be_displayed

  # Return the case we created using the params of the current  path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  Case::Base.find(kase_id)
end

def create_sar_case_step(params = {})
  flag_for_disclosure = params.delete(:flag_for_disclosure) { false }

  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click

  expect(cases_new_page).to be_displayed

  cases_new_page.create_link_for_correspondence("SAR - Subject access request").click
  expect(cases_new_sar_page).to be_displayed

  cases_new_sar_page.fill_in_case_details(params)
  scroll_to cases_new_sar_page.choose_flag_for_disclosure_specialists
  cases_new_sar_page.choose_flag_for_disclosure_specialists(
    flag_for_disclosure ? "yes" : "no",
  )
  click_button "Create case"

  # Return the case we created using the params of the current path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  expect(assignments_new_page).to be_displayed(case_id: kase_id)
  Case::Base.find(kase_id)
end

def create_offender_sar_case_step(params = {})
  # flag_for_disclosure = params.delete(:flag_for_disclosure) { false }

  # Assume we are on a case listing page
  expect(cases_page).to have_new_case_button
  cases_page.new_case_button.click
  expect(cases_new_page).to be_displayed

  cases_new_page.create_link_for_correspondence("OFFENDER").click
  expect(cases_new_offender_sar_subject_details_page).to be_displayed

  cases_new_offender_sar_subject_details_page.fill_in_case_details(params)
  click_on "Continue"
  expect(cases_new_offender_sar_requester_details_page).to be_displayed

  cases_new_offender_sar_requester_details_page.fill_in_case_details(params)
  click_on "Continue"
  expect(cases_new_offender_sar_requested_info_page).to be_displayed

  cases_new_offender_sar_requested_info_page.fill_in_case_details(params)
  click_on "Continue"
  expect(cases_new_offender_sar_date_received_page).to be_displayed

  cases_new_offender_sar_date_received_page.fill_in_case_details(params)
  click_on "Continue"

  expect(cases_show_page).to be_displayed
  expect(cases_show_page).to have_content "Case created successfully"
  expect(cases_show_page.page_heading).to have_content "Sabrina Adams"
  click_on "Cases"

  expect(open_cases_page).to be_displayed
  expect(cases_page).to have_content "Branston Registry"
  expect(open_cases_page).to have_content "Sabrina Adams"
end

def create_overturned_ico_case_step(params = {})
  ico_case = params.delete(:ico_case)
  flagged = params.delete(:flag_for_disclosure)
  case_type = params[:case_type].downcase

  cases_show_page.load(id: ico_case.id)
  expect(cases_show_page).to be_displayed(id: ico_case.id)
  # Replace the following-line with a click on the "New overturned case"
  # button when available
  cases_show_page.actions.create_overturned.click

  new_overturned_ico_page = if case_type.upcase == "SAR"
                              cases_new_sar_overturned_ico_page
                            else
                              cases_new_foi_overturned_ico_page
                            end

  expect(new_overturned_ico_page).to be_displayed(id: ico_case.id)
  expect(new_overturned_ico_page).to have_form
  expect(new_overturned_ico_page).to have_text(ico_case.number)

  form = new_overturned_ico_page.form

  final_deadline = 10.business_days.from_now
  form.final_deadline.day.set(final_deadline.day)
  form.final_deadline.month.set(final_deadline.month)
  form.final_deadline.year.set(final_deadline.year)

  expect(form.has_checked_field?("By email", visible: false)).to eq true
  expect(form.has_field?(
           "Name of the ICO information officer who's handling this case",
           with: ico_case.ico_officer_name,
           type: :text,
         )).to eq true

  if form.has_flag_for_disclosure_specialists?
    form.choose_flag_for_disclosure_specialists(flagged ? "yes" : "no",
                                                case_type: case_type.downcase)
  end

  click_button "Create case"

  # Return the case we created using the params of the current  path
  kase_id = Rails.application.routes.recognize_path(current_path)[:case_id]
  Case::Base.find(kase_id)
end
