require "rails_helper"

feature "commissioning document" do
  given(:manager) { find_or_create :branston_user }
  given(:offender_sar_case) { create(:offender_sar_case).decorate }
  given(:data_request_area) { create(:data_request_area, offender_sar_case:) }

  background do
    login_as manager
  end

  scenario "Download commissioning document" do
    create(:commissioning_document, data_request_area:)
    create(:data_request, data_request_area:)
    data_request_area_show_page.load(case_id: offender_sar_case.id, data_request_area_id: data_request_area.id)
    click_on "Download"

    expect(page.response_headers["Content-Disposition"]).to match(/filename=".*docx"/)
  end
end
