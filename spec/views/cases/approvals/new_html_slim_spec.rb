require "rails_helper"

describe "cases/approvals/new.html.slim", type: :view do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:foi_kase)              { create :pending_dacu_clearance_case }
  let(:late_foi_kase)         { create :pending_dacu_clearance_case, :late }
  let(:sar_kase)              { create :pending_dacu_clearance_sar }

  def render_page
    render

    cases_approve_page.load(rendered)
    cases_approve_page
  end

  before do
    login_as disclosure_specialist
  end

  it "displays the subject of the case being approved" do
    assign(:case, foi_kase.decorate)

    render_page

    expect(cases_approve_page).to have_clearance
    expect(cases_approve_page.clearance)
      .to have_text(foi_kase.subject)
  end

  describe "foi case" do
    it "displays a message about the next steps for this case" do
      assign(:case, foi_kase.decorate)

      render_page

      expect(cases_approve_page.clearance)
        .to have_text(I18n.t("cases.approvals.new.approve_message.foi",
                             managing_team: foi_kase.managing_team.name))
    end

    it "does not display a bypass section" do
      assign(:case, foi_kase.decorate)

      render_page

      expect(cases_approve_page).not_to have_bypass_press_option
    end
  end

  describe "sar case" do
    it "displays a message about the next steps for this case" do
      assign(:case, sar_kase.decorate)

      render_page

      expect(cases_approve_page.clearance)
        .to have_text(I18n.t("cases.approvals.new.approve_message.sar",
                             managing_team: foi_kase.managing_team.name))
    end
  end

  context "when case with full approval" do
    let(:foi_kase_full_approval) do
      create :pending_dacu_clearance_case,
             :full_approval
    end

    before do
      assign(:case, foi_kase_full_approval.decorate)
    end

    it "has the bypass section" do
      render_page

      expect(cases_approve_page).to have_bypass_press_option
    end

    it "renders the bypass form" do
      render_page

      expect(response).to have_rendered("cases/shared/_bypass_approvals_form")
    end
  end

  it "has a clear response button" do
    assign(:case, foi_kase.decorate)

    render_page

    expect(cases_approve_page).to have_clear_response_button
  end
end
