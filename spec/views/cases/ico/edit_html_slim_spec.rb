require "rails_helper"

describe "cases/edit.html.slim", type: :view do
  it "displays the edit case page" do
    related_case = create(:compliance_review)
    kase = create :approved_ico_foi_case,
                  related_cases: [related_case]

    assign(:correspondence_type_key, "ico")
    assign(:case, kase.decorate)
    assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(kase, :request))

    render

    cases_edit_ico_page.load(rendered)

    page = cases_edit_ico_page

    expect(page.page_heading.heading.text).to eq "Edit case details"
    expect(page.page_heading.sub_heading.text.strip)
      .to eq "#{kase.number} - ICO appeal (FOI)"

    expect(page.form.original_case).to have_linked_records(count: 1)
    original_case_section = page.form.original_case.linked_records.first
    expect(original_case_section.link).to have_text kase.original_case.number
    expect(original_case_section.case_type).to have_text "FOI"
    expect(original_case_section.request).to have_text kase.original_case.subject
    expect(original_case_section).to have_remove_link
    expect(original_case_section.remove_link.text).to eq "Remove link"

    expect(page.form.related_cases).to have_linked_records(count: 1)
    related_case_section = page.form.related_cases.linked_records.first
    expect(related_case_section.link).to have_text related_case.number
    expect(related_case_section.case_type)
      .to have_text related_case.decorate.pretty_type
    expect(related_case_section.request).to have_text related_case.subject
    expect(related_case_section).to have_remove_link
    expect(related_case_section.remove_link.text).to eq "Remove link"

    expect(page.form.date_received_day.value).to eq kase.received_date.day.to_s
    expect(page.form.date_received_month.value).to eq kase.received_date.month.to_s
    expect(page.form.date_received_year.value).to eq kase.received_date.year.to_s

    expect(page.form.external_deadline_day.value).to eq kase.external_deadline.day.to_s
    expect(page.form.external_deadline_month.value).to eq kase.external_deadline.month.to_s
    expect(page.form.external_deadline_year.value).to eq kase.external_deadline.year.to_s

    expect(page.form.internal_deadline_day.value).to eq kase.internal_deadline.day.to_s
    expect(page.form.internal_deadline_month.value).to eq kase.internal_deadline.month.to_s
    expect(page.form.internal_deadline_year.value).to eq kase.internal_deadline.year.to_s

    expect(page.form.date_draft_compliant_day.value).to eq kase.date_draft_compliant.day.to_s
    expect(page.form.date_draft_compliant_month.value).to eq kase.date_draft_compliant.month.to_s
    expect(page.form.date_draft_compliant_year.value).to eq kase.date_draft_compliant.year.to_s

    expect(page.form.root_element["action"]).to match(/^\/cases\/icos\/\d+$/)
    expect(page.form.case_details.value).to eq kase.message

    expect(page.form).to have_submit_button
    expect(page.form.submit_button.value).to eq "Save changes"
    expect(page).to have_cancel
  end
end
