require "rails_helper"

describe "cases/edit.html.slim", type: :view do
  it "displays the edit case page" do
    Timecop.freeze(Time.utc(2016, 8, 13, 12, 15, 45)) do
      kase = create :approved_sar,
                    subject_full_name: "John Doe",
                    subject_type: "member_of_the_public",
                    email: "jd@moj.com",
                    subject: "Court dates",
                    message: "When was I last in court",
                    received_date: Date.new(2016, 8, 10),
                    date_draft_compliant: Date.new(2016, 8, 12)

      assign(:correspondence_type_key, "sar")
      assign(:case, kase.decorate)

      render

      cases_edit_page.load(rendered)

      page = cases_edit_page

      expect(page.page_heading.heading.text).to eq "Edit case details"
      expect(page.page_heading.sub_heading.text.strip).to eq "#{kase.number} - SAR"

      expect(page.sar_detail.subject_name.value).to eq "John Doe"

      expect(page.sar_detail.third_party.yes).not_to be_checked
      expect(page.sar_detail.third_party.no).to be_checked

      expect(page.sar_detail.date_received_day.value).to eq "10"
      expect(page.sar_detail.date_received_month.value).to eq "8"
      expect(page.sar_detail.date_received_year.value).to eq "2016"

      expect(page.sar_detail.case_summary.value).to eq "Court dates"
      expect(page.sar_detail.full_request.value).to eq "When was I last in court"

      expect(page.sar_detail.send_by_email).to be_checked
      expect(page.sar_detail.email.value).to eq "jd@moj.com"

      expect(page.sar_detail.date_draft_compliant_day.value).to eq "12"
      expect(page.sar_detail.date_draft_compliant_month.value).to eq "8"
      expect(page.sar_detail.date_draft_compliant_year.value).to eq "2016"

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Save changes"
      expect(page).to have_cancel
    end
  end
end
