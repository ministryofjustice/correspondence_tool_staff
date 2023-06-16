require "rails_helper"

describe "cases/closable/closure_outcomes.html.slim" do
  context "with an FOI case" do
    let(:foi_being_drafted) { build_stubbed :case_being_drafted }

    it "renders the date_responded_form partial" do
      assign(:case, foi_being_drafted.decorate)
      render
      expect(response)
        .to have_rendered(
          partial: "cases/foi/closure_outcomes_form",
          locals: {
            kase: foi_being_drafted.decorate,
            submit_button: "Close case",
          },
        )
    end
  end

  context "with a SAR case" do
    let(:sar_being_drafted) { build_stubbed :sar_being_drafted }

    it "renders the date_responded_form partial" do
      assign(:case, sar_being_drafted.decorate)
      render
      expect(response)
        .to have_rendered(
          partial: "cases/sar/closure_outcomes_form",
          locals: {
            kase: sar_being_drafted,
            submit_button: "Close case",
          },
        )
    end

    it "does not set the value for missing_info" do
      assign(:case, sar_being_drafted.decorate)
      render
      cases_close_page.load(rendered)
      expect(cases_close_page.missing_info.yes).not_to be_checked
      expect(cases_close_page.missing_info.no).not_to be_checked
    end
  end

  context "with a ICO Appeal case" do
    # need to create instead of build_stubbed because s3 needs created case
    let(:ico_sent_and_awaiting_ico_decision) { create :responded_ico_foi_case }

    it "renders the close_form partial" do
      assign(:case, ico_sent_and_awaiting_ico_decision.decorate)
      assign(:s3_direct_post,
             S3Uploader.s3_direct_post_for_case(ico_sent_and_awaiting_ico_decision,
                                                :request))
      render
      expect(response)
        .to have_rendered(
          partial: "cases/ico/closure_outcomes_form",
          locals: {
            kase: ico_sent_and_awaiting_ico_decision,
            submit_button: "Close case",
          },
        )
    end

    it "ICO Decision" do
      assign(:case, ico_sent_and_awaiting_ico_decision.decorate)
      assign(:s3_direct_post,
             S3Uploader.s3_direct_post_for_case(ico_sent_and_awaiting_ico_decision,
                                                :request))

      render
      cases_close_page.load(rendered)
      expect(cases_close_page.ico).to have_ico_decision
      expect(cases_close_page.ico.ico_decision.overturned_label).to have_text(:all, "Overturned by ICO")
      expect(cases_close_page.ico.ico_decision.upheld_label).to have_text(:all, "Upheld by ICO")
    end

    it "ICO Decision uploads" do
      assign(:case, ico_sent_and_awaiting_ico_decision.decorate)
      assign(:s3_direct_post,
             S3Uploader.s3_direct_post_for_case(ico_sent_and_awaiting_ico_decision,
                                                :request))

      render
      cases_close_page.load(rendered)
      expect(cases_close_page.ico).to have_uploads
    end
  end
end
