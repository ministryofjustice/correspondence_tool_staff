require "rails_helper"

feature "Editing a case" do
  background do
    team = find_or_create :team_dacu
    bmt_user = team.users.first
    login_as bmt_user
  end

  scenario "editing a case" do
    kase = create :case, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed

    cases_edit_page.foi_detail.date_received_day.set(Time.zone.today.day)
    cases_edit_page.foi_detail.date_received_month.set(Time.zone.today.month)
    cases_edit_page.foi_detail.date_received_year.set(Time.zone.today.year)
    cases_edit_page.foi_detail.subject.set("Aardvarks for sale")
    cases_edit_page.foi_detail.full_request.set("I have heard that prisoners are selling baby aardvarks.  Is that true?")
    cases_edit_page.foi_detail.full_name.set("John Doe")
    cases_edit_page.foi_detail.email.set("john.doe@moj.com")
    cases_edit_page.submit_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.notice.text).to eq "Case updated"
    expect(cases_show_page.page_heading.heading.text).to eq "Case subject, Aardvarks for sale"
    expect(cases_show_page.case_details.foi_basic_details.date_received.data.text).to eq Time.zone.today.strftime(Settings.default_date_format)
    expect(cases_show_page.case_details.foi_basic_details.name.data.text).to eq "John Doe"
    expect(cases_show_page.case_details.foi_basic_details.email.data.text).to eq "john.doe@moj.com"
  end

  scenario "editing a case and requestor type is displayed" do
    kase = create :case, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed
    expect(cases_edit_page).to have_checked_field("Member of the public")

  end

  scenario "editing a case with no changes" do
    kase = create :accepted_case, received_date: 2.days.ago
    open_cases_page.load
    click_link kase.number
    expect(cases_show_page).to be_displayed
    click_link "Edit case details"
    expect(cases_edit_page).to be_displayed

    cases_edit_page.submit_button.click

    expect(cases_show_page).to be_displayed
    expect(cases_show_page.alert.text).to eq "No changes were made"
  end

  scenario "Uploading new request files", js: true do
    kase = create :accepted_case, :case_sent_by_post, received_date: 2.days.ago
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
