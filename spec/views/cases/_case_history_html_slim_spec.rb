require 'rails_helper'

describe 'cases/case_history.html.slim', type: :view do

  it 'displays the section heading' do
    first  = double CaseTransitionDecorator,
                    action_date: (DateTime.now + 10.days).strftime('%d %b %Y %H:%M'),
                    user_name: 'Tom Smith',
                    user_team: 'Managing Team 1',
                    event_and_detail: 'Created new case'

    transitions = [first]

    assign(:case_transitions, transitions)
    render partial: 'cases/case_history',
              locals:{ case_details: first}

    partial = case_history_section(rendered)

    expect(partial.section_heading.text).to eq 'Case history'
  end

  it 'displays date, user, team and event details' do
    first  = double CaseTransitionDecorator,
                    action_date: (DateTime.now + 10.days).strftime('%d %b %Y<br>%H:%M'),
                    user_name: 'Tom Smith',
                    user_team: 'Managing Team 1',
                    event_and_detail: 'Created new case'

    transitions = [first]

    assign(:case_transitions, transitions)
    render partial: 'cases/case_history',
              locals:{ case_details: first}

    partial = case_history_section(rendered)

    expect(partial.rows.first.action_date.text).to eq first.action_date
    expect(partial.rows.first.user.text).to eq first.user_name
    expect(partial.rows.first.team.text).to eq first.user_team
    expect(partial.rows.first.details.text).to eq first.event_and_detail

  end
end
