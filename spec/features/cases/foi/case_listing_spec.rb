require 'rails_helper'
require 'rspec/expectations'

RSpec::Matchers.define :match_the_case do |kase|
  define_method :case_states do
    {
      'unassigned' => 'Allocation',
      'awaiting_dispatch' => 'Awaiting Dispatch',
      'awaiting_responder' => 'Acceptance',
      'awaiting_responder_email' => 'Waiting to be accepted',
      'drafting' => 'Response',
      'responded' => 'Closure',
      'closed' => 'Case closed',
    }
  end

  match do |actual|
    expect(actual.name.text).to eq kase.name
    expect(actual.subject.text).to eq kase.subject
    expect(actual.status.text).to eq case_states[kase.current_state]
    expect(actual.external_deadline.text)
      .to have_content(kase.external_deadline.strftime('%e %b %Y'))
    expect(actual.number)
      .to have_link("#{kase.number}", href: case_path(kase.id))
    expect(actual.who_its_with.text).to eq @with_text if @with_text
  end

  chain :and_be_with do |with_text|
    @with_text = with_text
  end

  failure_message do |actual|
    message = ''
    unless actual.name.text == kase.name
      message += <<EOM
  expected case name: #{kase.name}
       got case name: #{actual.name.text}
EOM
    end
    unless actual.subject.text == kase.subject
      message += <<EOM
  expected case subject: #{kase.subject}
    actual case subject: #{actual.subject.text}
EOM
    end
    unless actual.status.text == case_states[kase.current_state]
      message += <<EOM
  expected case state: #{case_states[kase.current_state]}
    actual case state: #{actual.status.text}
EOM
    end
    unless actual.external_deadline.text
             .include? kase.external_deadline.strftime('%e %b %Y')
      message += <<EOM
  expected case external deadline: #{kase.external_deadline.strftime('%e %b %Y')}
    actual case external deadline: #{actual.external_deadline.text}
EOM
    end
    unless actual.number.has_link? kase.number, href: case_path(kase.id)
      message += <<EOM
  expected case number to be a link to: #{case_path(kase.id)}
EOM
    end
    unless @with_text.nil? || actual.who_its_with.text == @with_text
      message += <<EOM
  expected case to be with: #{@with_text}
       actual case is with: #{actual.who_its_with.text}
EOM
    end
    message
  end
end


feature 'listing cases on the system' do
  given(:foi_category) { create(:category) }
  given(:responder_a) { create :responder,
                               full_name: 'Responder A',
                               responding_teams: [responding_team_a] }
  given(:responder_b) { create :responder,
                               full_name: 'Responder B',
                               responding_teams: [responding_team_b] }
  given(:responding_team_a) { create :responding_team, name: 'Responding Team A' }
  given(:responding_team_b) { create :responding_team, name: 'Responding Team B' }
  given(:coresponder_a)     { create :responder,
                                     full_name: 'Co-Responder A',
                                     responding_teams: [responding_team_a] }

  given(:unassigned_case) do
    create :case,
           name: 'Freddie FOI Unassigned',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test unassigned FOI subject',
           message: 'viewing unassigned foi details test message',
           category: foi_category
  end
  given(:assigned_case_team_a) do
    create :assigned_case,
           name: 'Freddie FOI Assigned',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test assigned FOI subject',
           message: 'viewing assigned foi details test message',
           category: foi_category,
           responding_team: responding_team_a
  end
  given(:assigned_case_team_b) do
    create :assigned_case,
           name: 'Freddie FOI Assigned',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test assigned FOI subject',
           message: 'viewing assigned foi details test message',
           category: foi_category,
           responding_team: responding_team_b
  end
  given(:accepted_case_team_a) do
    create :accepted_case,
           name: 'Freddie FOI Accepted',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test accepted FOI subject',
           message: 'viewing accepted foi details test message',
           category: foi_category,
           responder: responder_a
  end
  given(:accepted_case_team_b) do
    create :accepted_case,
           name: 'Freddie FOI Accepted',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test accepted FOI subject',
           message: 'viewing accepted foi details test message',
           category: foi_category,
           responder: responder_b
  end
  given(:rejected_case_team_a) do
    create :rejected_case,
           name: 'Freddie FOI Rejected',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test rejected FOI subject',
           message: 'viewing rejected foi details test message',
           category: foi_category,
           responder: responder_a
  end
  given(:rejected_case_team_b) do
    create :rejected_case,
           name: 'Freddie FOI Rejected',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test rejected FOI subject',
           message: 'viewing rejected foi details test message',
           category: foi_category,
           responder: responder_b
  end
  given(:case_with_response_team_a) do
    create :case_with_response,
           name: 'Freddie FOI With Response',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test case with response FOI subject',
           message: 'viewing case with response foi details test message',
           category: foi_category,
           responder: responder_a
  end
  given(:case_with_response_team_b) do
    create :case_with_response,
           name: 'Freddie FOI With Response',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test case with response FOI subject',
           message: 'viewing case with response foi details test message',
           category: foi_category,
           responder: responder_b
  end
  given(:responded_case_team_a) do
    create :responded_case,
           name: 'Freddie FOI Responded',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test responded FOI subject',
           message: 'viewing responded foi details test message',
           category: foi_category,
           responder: responder_a
  end
  given(:responded_case_team_b) do
    create :responded_case,
           name: 'Freddie FOI Responded',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test responded FOI subject',
           message: 'viewing responded foi details test message',
           category: foi_category,
           responder: responder_b
  end
  given(:closed_case_team_a) do
    create :responded_case,
           name: 'Freddie FOI Closed',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test closed FOI subject',
           message: 'viewing closed foi details test message',
           category: foi_category,
           responder: responder_a
  end
  given(:closed_case_team_b) do
    create :responded_case,
           name: 'Freddie FOI Closed',
           email: 'freddie.foi@testing.digital.justice.gov.uk',
           subject: 'test closed FOI subject',
           message: 'viewing closed foi details test message',
           category: foi_category,
           responder: responder_b
  end

  background do
    # Create our cases
    unassigned_case
    assigned_case_team_a
    assigned_case_team_b
    accepted_case_team_a
    accepted_case_team_b
    rejected_case_team_a
    rejected_case_team_b
    case_with_response_team_a
    case_with_response_team_b
    responded_case_team_a
    responded_case_team_b
    closed_case_team_a
    closed_case_team_b
  end

  scenario 'for managers - shows all cases' do
    login_as create(:manager)
    visit '/'
    cases = cases_page.case_list
    expect(cases.count).to eq 13

    expect(cases[0]).to match_the_case(unassigned_case).and_be_with('DACU')
    expect(cases[1]).to match_the_case(assigned_case_team_a)
                          .and_be_with('Responding Team A')
    expect(cases[2]).to match_the_case(assigned_case_team_b)
                          .and_be_with('Responding Team B')
    expect(cases[3]).to match_the_case(accepted_case_team_a)
                          .and_be_with('Responding Team A')
    expect(cases[4]).to match_the_case(accepted_case_team_b)
                          .and_be_with('Responding Team B')
    expect(cases[5]).to match_the_case(rejected_case_team_a)
                          .and_be_with('DACU')
    expect(cases[6]).to match_the_case(rejected_case_team_b)
                          .and_be_with('DACU')
    expect(cases[7]).to match_the_case(case_with_response_team_a)
                          .and_be_with('Responding Team A')
    expect(cases[8]).to match_the_case(case_with_response_team_b)
                          .and_be_with('Responding Team B')
    expect(cases[9]).to match_the_case(responded_case_team_a)
                          .and_be_with('DACU')
    expect(cases[10]).to match_the_case(responded_case_team_b)
                           .and_be_with('DACU')
  end

  scenario 'For responders - shows only their assigned and accepted cases' do
    login_as responder_a
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_a)
                             .and_be_with('Responding Team A')
    expect(cases.second).to match_the_case(accepted_case_team_a)
                              .and_be_with('Responder A')
    expect(cases.third).to match_the_case(case_with_response_team_a)
                             .and_be_with('Responder A')
  end

  scenario 'For responder coworkers - shows teams assigned and accepted cases' do
    login_as coresponder_a
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_a)
                             .and_be_with('Responding Team A')
    expect(cases.second).to match_the_case(accepted_case_team_a)
                              .and_be_with('Responder A')
    expect(cases.third).to match_the_case(case_with_response_team_a)
                             .and_be_with('Responder A')
  end

  scenario 'For responders on other teams - shows their cases' do
    login_as responder_b
    visit '/'

    cases = cases_page.case_list
    expect(cases.count).to eq 3

    expect(cases.first).to match_the_case(assigned_case_team_b)
                             .and_be_with('Responding Team B')
    expect(cases.second).to match_the_case(accepted_case_team_b)
                              .and_be_with('Responder B')
    expect(cases.third).to match_the_case(case_with_response_team_b)
                             .and_be_with('Responder B')
  end
end
