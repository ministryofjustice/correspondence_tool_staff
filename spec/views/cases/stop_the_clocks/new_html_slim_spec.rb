require "rails_helper"

describe "cases/stop_the_clocks/new.html.slim", type: :view do
  describe "#new" do
    let(:offender_sar) { create :offender_sar_case }
    let(:page) { cases_stop_the_clock_page }

    before do
      assign(:case, CaseStopTheClockDecorator.decorate(offender_sar))

      render
      page.load(rendered)
    end

    it "has required content" do
      expect(page.page_heading.heading.text).to eq "Stop the clock on this case"
      # Checkboxes
      expect(page).to have_stop_the_clock_reason
      expect(page).to have_stop_the_clock_date_day
      expect(page).to have_stop_the_clock_date_month
      expect(page).to have_stop_the_clock_date_year
      expect(page.submit_button.value).to eq "Stop the clock"
      expect(page).to have_cancel
    end

    it "renders all stop the clock checkbox values" do
      values = [
        "To clarify something - CCTV or BWCF requirements",
        "To clarify something - Telephone recording requirements",
        "To clarify something - Refine or reduce the scope",
        "To clarify something - Another question about the requirements",
        "To request more information - Search location",
        "To request more information - Unique identifier (such as National Insurance number or date of birth)",
        "To request more information - Names and email address of individuals (staff requests only)",
        "Something else - Request is illegible or unreadable",
        "Something else - Respondent's name or address is different",
        "Something else - Another reason",
      ]

      values.each do |value|
        expect(rendered).to have_selector("input[type=checkbox][value=\"#{value}\"]")
      end
    end
  end
end
