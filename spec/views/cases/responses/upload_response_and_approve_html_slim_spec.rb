require "rails_helper"

describe "cases/responses/upload_response_and_approve.html.slim", type: :view do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:kase) { create :pending_dacu_clearance_case }

  before do
    login_as disclosure_specialist

    assign(:case, kase.decorate)
    assign(:action, "upload_response_and_approve")
    assign(:s3_direct_post,
           S3Uploader.s3_direct_post_for_case(kase, :response))
  end

  def render_page
    render

    cases_upload_response_and_approve_page.load(rendered)
    cases_upload_response_and_approve_page
  end

  it "displays the upload response form" do
    page = render_page

    expect(page.upload_response_form[:action])
      .to eq case_responses_path(kase)
    expect(page.response_action(visible: false).value)
      .to eq "upload_response_and_approve"
  end

  it "displays the uploader" do
    page = render_page

    expect(page).to have_dropzone_container
    expect(response).to have_rendered("_response_upload_form")
  end

  context "trigger foi case" do
    let(:kase) { create :pending_dacu_clearance_case }

    it "does not display the bypass options" do
      page = render_page

      expect(page).not_to have_bypass_press_option
      expect(response).not_to have_rendered("cases/shared/_bypass_approvals_form")
    end
  end

  context "full approval foi case" do
    let(:kase) { create :pending_dacu_clearance_case, :full_approval }

    it "displays the bypass options" do
      page = render_page

      expect(page).to have_bypass_press_option
      expect(response).to have_rendered("cases/shared/_bypass_approvals_form")
    end
  end

  it "displays the upload button" do
    page = render_page

    expect(page.upload_response_button.value).to eq "Upload response"
  end
end
