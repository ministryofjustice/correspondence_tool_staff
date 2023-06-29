require "rails_helper"

describe "cases/edit.html.slim", type: :view do
  it "displays the edit case page" do
    Timecop.freeze(Time.zone.local(2016, 8, 13, 12, 15, 45)) do
      kase = create :approved_case, name: "John Doe",
                                    email: "jd@moj.com",
                                    requester_type: :journalist,
                                    subject: "Ferrets",
                                    message: "Can I keep a ferret in jail",
                                    received_date: Date.new(2016, 8, 10),
                                    date_draft_compliant: Date.new(2016, 8, 12)

      assign(:correspondence_type_key, "foi")
      assign(:case, kase.decorate)

      render

      cases_edit_page.load(rendered)

      page = cases_edit_page

      expect(page.page_heading.heading.text).to eq "Edit case details"
      expect(page.page_heading.sub_heading.text.strip).to eq "#{kase.number} - FOI"

      expect(page.foi_detail.date_received_day.value).to eq "10"
      expect(page.foi_detail.date_received_month.value).to eq "8"
      expect(page.foi_detail.date_received_year.value).to eq "2016"

      expect(page.foi_detail.form["action"]).to match(/^\/cases\/fois\/\d+$/)

      expect(page.foi_detail.subject.value).to eq "Ferrets"
      expect(page.foi_detail.full_request.value).to eq "Can I keep a ferret in jail"
      expect(page.foi_detail.full_name.value).to eq "John Doe"
      expect(page.foi_detail.email.value).to eq "jd@moj.com"
      expect(page.foi_detail).to have_address
      expect(page.foi_detail.date_draft_compliant_day.value).to eq "12"
      expect(page.foi_detail.date_draft_compliant_month.value).to eq "8"
      expect(page.foi_detail.date_draft_compliant_year.value).to eq "2016"

      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Save changes"
      expect(page).to have_cancel
    end
  end
end
