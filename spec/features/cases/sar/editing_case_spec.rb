require "rails_helper"

feature "Editing a SAR case" do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario "editing a case" do
    kase = create :accepted_sar, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed

    detail = cases_edit_page.sar_detail
    detail.subject_name.set("Stepriponikas Bonstart")

    cases_edit_page.sar_detail.date_received_day.set(Time.zone.today.day)
    cases_edit_page.sar_detail.date_received_month.set(Time.zone.today.month)
    cases_edit_page.sar_detail.date_received_year.set(Time.zone.today.year)

    cases_edit_page.sar_detail.case_summary.set("Aardvarks for sale")
    cases_edit_page.sar_detail.full_request.set("I have heard that prisoners are selling baby aardvarks.  Is that true?")
    cases_edit_page.submit_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.notice.text).to eq "Case updated"

    expect(cases_show_page.page_heading.heading.text).to eq "Case subject, Aardvarks for sale"
    expect(cases_show_page.case_details.sar_basic_details.data_subject.data.text).to eq "Stepriponikas Bonstart"
    expect(cases_show_page.case_details.sar_basic_details.date_received.data.text).to eq Time.zone.today.strftime(Settings.default_date_format)
  end

  scenario "editing a case and subject type is displayed" do
    kase = create :accepted_sar, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed
    expect(cases_edit_page).to have_checked_field("Offender")
  end

  scenario "Uploading new request files", js: true do
    kase = create :accepted_sar, :case_sent_by_post, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link "Upload request files"
    expect(cases_upload_requests_page).to be_displayed

    request_attachment = Rails.root.join("spec/fixtures/request-1.pdf")
    cases_upload_requests_page.drop_in_dropzone(request_attachment)
    cases_upload_requests_page.upload_requests_button.click
    expect(cases_show_page).to be_displayed
    expect(cases_show_page).to have_content(I18n.t("notices.request_uploaded"))
    request_attachment = kase.attachments.request.first
    expect(request_attachment.key).to match %(/request-1.pdf$)
  end
end
