require 'rails_helper'

describe 'cases/new_response_upload.html.slim', type: :view do

  let(:disclosure_specialist)     { create :disclosure_specialist, full_name: 'Dack Dispirito' }
  let(:responder)                 { create :user, full_name: 'Ralph Responder' }
  let(:responding_team)           { create :responding_team, responders: [responder], lead: create(:team_property, :lead, value: 'Margaret Thatcher') }

  let(:foi_case)                  { create :pending_dacu_clearance_case,
                                           responding_team: responding_team,
                                           responder: responder,
                                           approver: disclosure_specialist }

  before(:each) { allow(controller).to receive(:current_user).and_return(disclosure_specialist) }

  it 'displays the new response page for FOI' do

    assign(:case, foi_case)

    render

    cases_respond_page.load(rendered)

    page = cases_respond_page

    expect(page.page_heading.heading.text).to eq "Mark as sent#{foi_case.subject}"
    expect(page.page_heading.sub_heading.text).to eq "You are viewing case number #{foi_case.number} - FOI "

    expect(page).to have_foi_task_reminder

    expect(page).to have_submit_button

    expect(page).to have_back_link
  end
end
