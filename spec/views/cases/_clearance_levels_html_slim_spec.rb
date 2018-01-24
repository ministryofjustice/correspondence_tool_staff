require 'rails_helper'

describe 'cases/clearance_details.html.slim', type: :view do

  # teams
  let(:team_dacu_disclosure)                    { find_or_create :team_dacu_disclosure }
  let(:team_press_office)                       { find_or_create :team_press_office }
  let(:team_private_office)                     { find_or_create :team_private_office }
  let(:responding_team)                         { create :responding_team, responders: [responder], lead: create(:team_property, :lead, value: 'Margaret Thatcher') }

  #users
  let(:disclosure_specialist)                   { create :disclosure_specialist }
  let(:responder)                               { create :user, full_name: 'Ralph Responder' }
  let(:dack)                                    { create :disclosure_specialist, full_name: 'Dack Dispirito' }

  #cases
  let(:accepted_case)                           { create :accepted_case, responding_team: responding_team, responder: responder }
  let(:unaccepted_pending_dacu_clearance_case)  { create :unaccepted_pending_dacu_clearance_case,
                                                         responding_team: responding_team,
                                                         responder: responder }
  let(:accepted_pending_dacu_clearance_case)    { create :pending_dacu_clearance_case,
                                                         responding_team: responding_team,
                                                         responder: responder,
                                                         approver: dack }
  let(:triple_flagged_case)                     { create :pending_dacu_clearance_case_flagged_for_press_and_private,
                                                         responding_team: responding_team,
                                                         responder: responder,
                                                         approver: dack,
                                                         private_officer: create(:private_officer, full_name: 'Prince Johns'),
                                                         press_officer: create(:press_officer, full_name: 'Alistair Campbell') }


  def allow_case_policies(kase, *policy_names)
    policy = double 'Pundit::Policy'
    policy_names.each do |policy_name|
      allow(policy).to receive(policy_name).and_return(true)
    end
    allow(view).to receive(:policy).with(kase).and_return(policy)
  end


  before(:each) { allow(controller).to receive(:current_user).and_return(disclosure_specialist) }

  context 'escalation_deadline not yet reached' do
    it 'just displays escalation date' do
      kase = create :case
      allow(kase).to receive(:escalation_deadline).and_return('13 Aug 2017')
      allow(kase).to receive(:within_escalation_deadline?).and_return(true)

      allow_case_policies kase.decorate, :request_further_clearance?

      render partial: 'cases/clearance_levels.html.slim',
                 locals:{ case_details: kase }

      partial = clearance_levels_section(rendered)
      expect(partial.escalation_deadline.text).to eq 'To be decided by  13 Aug 2017'
      expect(partial).to have_escalate_link
    end
  end

  context 'escalation deadline reached' do
    context 'case not flagged for approval' do
      it 'displays the name of the deputy director of the responding team' do

        allow_case_policies accepted_case.decorate, :request_further_clearance?

        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: accepted_case.decorate }
        partial = clearance_levels_section(rendered)

        expect(partial.basic_details.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial.basic_details).to have_no_dacu_disclosure
        expect(partial).to have_escalate_link
      end
    end

    context 'case flagged for approval by DACU Disclosure but not yet accepted by disclosure team member' do
      it 'displays the name of the deputy director of the responding team' do

        allow_case_policies unaccepted_pending_dacu_clearance_case.decorate, :request_further_clearance?

        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details:unaccepted_pending_dacu_clearance_case.decorate }
        partial = clearance_levels_section(rendered)

        expect(partial.basic_details.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial.basic_details).to have_no_dacu_disclosure
        expect(partial).to have_escalate_link
      end
    end

    context 'case flagged and accepted for approval by DACU disclosure only' do
      it 'displays the name of the deputy director and the name of the dacu disclosure approver' do

        allow_case_policies accepted_pending_dacu_clearance_case.decorate, :request_further_clearance?

        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: accepted_pending_dacu_clearance_case.decorate }
        partial = clearance_levels_section(rendered)

        expect(partial.basic_details.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial.basic_details.dacu_disclosure.text).to include 'Dack Dispirito'
        expect(partial.basic_details.dacu_disclosure.text).to include 'Remove clearance'
        expect(partial).to have_escalate_link
      end
    end

    context 'case flagged and accepted for approval by DACU Disclosure, Press and Private offices' do
      it 'displays details of all approvers' do

        allow_case_policies triple_flagged_case.decorate, :request_further_clearance?

        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: triple_flagged_case.decorate }
        partial = clearance_levels_section(rendered)

        basic_dets = partial.basic_details
        expect(basic_dets.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(basic_dets.dacu_disclosure.text).to include 'Dack Dispirito'
        expect(basic_dets.dacu_disclosure.text).not_to include 'Remove clearance'

        approver_dets = partial.basic_details.press_office
        expect(approver_dets.department_name.text).to eq 'Press Office'
        expect(approver_dets.approver_name.text).to eq 'Alistair Campbell'

        approver_dets = partial.basic_details.private_office
        expect(approver_dets.department_name.text).to eq 'Private Office'
        expect(approver_dets.approver_name.text).to eq 'Prince Johns'
      end
    end
  end

end
