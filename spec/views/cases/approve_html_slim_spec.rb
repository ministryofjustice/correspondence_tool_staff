require 'rails_helper'

describe 'cases/approve.html.slim', type: :view do
  let(:disclosure_specialist) { find_or_create :disclosure_specialist }
  let(:foi_kase)              { create :pending_dacu_clearance_case }
  let(:late_foi_kase)         { create :pending_dacu_clearance_case, :late }
  let(:sar_kase)              { create :pending_dacu_clearance_sar }

  def render_partial
    render

    cases_approve_page.load(rendered)
  end

  before do
    login_as disclosure_specialist
  end

  it 'displays the subject of the case being approved' do
    assign(:case, foi_kase.decorate)

    render_partial

    expect(cases_approve_page).to have_clearance
    expect(cases_approve_page.clearance)
      .to have_text(foi_kase.subject)
  end

  context 'foi case' do
    it 'displays a message about the next steps for this case' do
      assign(:case, foi_kase.decorate)

      render_partial

      expect(cases_approve_page.clearance)
        .to have_text(I18n.t('cases.approve.approve_message.foi',
                             managing_team: foi_kase.managing_team.name))
    end
  end

  context 'sar case' do
    it 'displays a message about the next steps for this case' do
      assign(:case, sar_kase.decorate)

      render_partial

      expect(cases_approve_page.clearance)
        .to have_text(I18n.t('cases.approve.approve_message.sar',
                             managing_team: foi_kase.managing_team.name))
    end
  end

  context 'late case with full approval' do
    let(:late_foi_kase_full_approval) { create :pending_dacu_clearance_case,
                                               :full_approval,
                                               :late }
    it 'renders the bypass form' do
      assign(:case, late_foi_kase_full_approval.decorate)

      render_partial

      expect(response).to have_rendered('cases/_bypass_approvals_form')
    end

  end

  it 'has a clear response button' do
    assign(:case, foi_kase.decorate)

    render_partial

    expect(cases_approve_page).to have_clear_response_button
  end
end
