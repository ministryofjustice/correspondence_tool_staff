require "rails_helper"

describe "cases/responses/upload_response_and_return_for_redraft.html.slim", type: :view do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:kase) { create :pending_dacu_clearance_case }

  before do
    login_as disclosure_specialist

    assign(:case, kase.decorate)
    assign(:action, "upload_response_and_return_for_redraft")
    assign(:s3_direct_post,
           S3Uploader.s3_direct_post_for_case(kase, :response))
  end

  def render_page
    render

    cases_upload_response_and_return_for_redraft_page.load(rendered)
    cases_upload_response_and_return_for_redraft_page
  end

  it "displays the uploader" do
    page = render_page

    expect(page).to have_dropzone_container
    expect(response).to have_rendered("_response_upload_form")
  end

  it "displays radio buttons for draft compliance" do
    page = render_page

    expect(page).to have_draft_compliant
  end

  it "displays the upload button" do
    page = render_page
    expect(page.upload_response_button.value).to eq "Upload response"
  end

  it "has the correct response action" do
    page = render_page
    expect(page.response_action(visible: false).value)
      .to eq "upload_response_and_return_for_redraft"
  end
end
