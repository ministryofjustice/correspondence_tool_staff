require 'rails_helper'

describe 'cases/approve_response.html.slim' do
  let!(:dacu_disclosure)        { create :team_dacu_disclosure }
  let(:disclosure_specialist)   { create :disclosure_specialist }
  let(:assigned_trigger_case)   { create :pending_dacu_clearance_case,
                                         :flagged_accepted,
                                         approver: disclosure_specialist }
  let(:nsi)                     { NextStepInfo.new(assigned_trigger_case,
                                                   'approve',
                                                   disclosure_specialist) }

  it 'displays all the cases' do
    assign(:case, assigned_trigger_case)
    assign(:next_step_info, nsi)
    render

    approve_response_page.load(rendered)
    page = approve_response_page

    expect(page.page_heading.heading.text).to eq "Clear response"
    expect(page.page_heading.sub_heading.text)
        .to eq "You are viewing case number #{assigned_trigger_case.number} "

    expect(page).to have_clearance

    expect(page).to have_submit_button
  end
end
