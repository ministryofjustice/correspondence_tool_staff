require "rails_helper"

describe "cases/attachments/new.html.slim", type: :view do
  let(:drafting_case) { build_stubbed(:accepted_case, :taken_on_by_press).decorate }

  after(:all) { DbHousekeeping.clean(seed: true) }

  it "displays the uploader" do
    assign(:case, drafting_case)
    assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(drafting_case, :request))
    render

    cases_upload_requests_page.load(rendered)

    page = cases_upload_requests_page

    expect(page.upload_requests_button.value).to eq "Confirm"
    expect(page).to have_content(I18n.t("cases.attachments.upload_request_files_heading"))
  end
end
