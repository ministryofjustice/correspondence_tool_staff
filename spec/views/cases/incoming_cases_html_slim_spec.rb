require 'rails_helper'
require 'capybara/dsl'

describe 'cases/incoming_cases.html.slim', type: :view do
  let(:approver) { create :approver }
  let(:approving_team) { approver.approving_teams.first }
  let(:case1) { create(:assigned_case, :flagged,
                       approving_team: approving_team,
                       name: 'Joe Smith',
                       subject: 'Prison Reform',
                       message: 'message number 1').decorate }
  let(:case2) { create(:assigned_case, :flagged,
                       approving_team: approving_team,
                       name: 'Jane Doe',
                       subject: 'Court Reform',
                       message: 'message number 2').decorate }

  it 'displays the cases given it' do
    assign(:cases, [case1, case2])

    policy = double('Pundit::Policy', can_add_case?: false)
    allow(view).to receive(:policy).with(:case).and_return(policy)

    sign_in approver

    render
    incoming_cases_page.load(rendered)

    first_case = incoming_cases_page.case_list[0]
    expect(first_case.number.text).to eq "Link to case #{case1.number}"
    expect(first_case.request.name.text).to eq 'Joe Smith | Member of the public'
    expect(first_case.request.subject.text).to eq 'Prison Reform'
    expect(first_case.request.message.text).to eq 'message number 1'
    expect(first_case.actions.take_on_case.text).to eq 'Take case on'
    expect(first_case.actions.de_escalate_link.text).to eq 'De-escalate'

    second_case = incoming_cases_page.case_list[1]
    expect(second_case.number.text).to eq "Link to case #{case2.number}"
    expect(second_case.request.name.text).to eq 'Jane Doe | Member of the public'
    expect(second_case.request.subject.text).to eq 'Court Reform'
    expect(second_case.request.message.text).to eq 'message number 2'
    expect(second_case.actions.take_on_case.text).to eq 'Take case on'
    expect(second_case.actions.de_escalate_link.text).to eq 'De-escalate'
  end

end
