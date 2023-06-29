require "rails_helper"

describe "cases/responses/upload_responses.html.slim", type: :view do
  let(:drafting_case) { build_stubbed(:accepted_case, :taken_on_by_press).decorate }
  let(:pending_clearance_case) { build_stubbed(:approved_ico_foi_case).decorate }

  it "displays the uploader" do
    assign(:case, drafting_case)
    assign(:action, "upload_responses")
    assign(:s3_direct_post, S3Uploader.s3_direct_post_for_case(drafting_case, :response))
    params[:mode] = "upload"
    render

    cases_upload_responses_page.load(rendered)

    page = cases_upload_responses_page

    expect(page.upload_response_button.value).to eq "Upload response"
    expect(page.response_action(visible: false).value).to eq "upload_responses"
  end
end
