require 'rails_helper'

describe 'cases/clearance_details.html.slim', type: :view do

  let(:team_dacu_disclosure)    { find_or_create :team_dacu_disclosure }
  let(:team_press_office)            { find_or_create :team_press_office }
  let(:team_private_office)            { find_or_create :team_private_office }

  context 'escalation_deadline not yet reached' do
    it 'just displays escalation date' do
      kase = double CaseDecorator
      allow(kase).to receive(:escalation_deadline).and_return('13 Aug 2017')
      allow(kase).to receive(:within_escalation_deadline?).and_return(true)

      render partial: 'cases/clearance_levels.html.slim',
                 locals:{ case_details: kase}

      partial = clearance_levels_section(rendered)


      expect(partial.escalation_deadline.text).to eq 'To be decided by  13 Aug 2017'
    end
  end

  context 'escalation deadline reached' do
    let(:kase)  { double CaseDecorator }

    before(:each) do
      @kase = double CaseDecorator
      allow(@kase).to receive(:within_escalation_deadline?).and_return(false)
      allow(@kase).to receive(:responding_team_lead_name).and_return('Margaret Thatcher')
      @dts = double DefaultTeamService
      allow(@kase).to receive(:default_team_service).and_return(@dts)
      allow(@dts).to receive(:approving_team).and_return(team_dacu_disclosure)
      allow(@kase).to receive(:default_clearance_approver).and_return('Dack Dispirito')
    end

    context 'case not flagged for approval' do
      it 'displays the name of the deputy director of the responding team' do
        allow(@kase).to receive(:approvers).and_return([])
        allow(@kase).to receive(:non_default_approver_assignments).and_return([])
        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: @kase}
        partial = clearance_levels_section(rendered).basic_details

        expect(partial.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial).to have_no_dacu_disclosure
      end
    end

    context 'case flagged for approval by DACU Disclosure but not yet accepted by disclosure team member' do
      it 'displays the name of the deputy director of the responding team' do
        allow(@kase).to receive(:approvers).and_return([])
        allow(@kase).to receive(:non_default_approver_assignments).and_return([])
        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: @kase}
        partial = clearance_levels_section(rendered).basic_details

        expect(partial.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial).to have_no_dacu_disclosure
      end
    end

    context 'case flagged and accepted for approval by DACU disclosure only' do
      it 'displays the name of the deputy direcyor and the name of the dacu disclosure approver' do
        allow(@kase).to receive(:approvers).and_return([ double(User) ])
        allow(@kase).to receive(:non_default_approver_assignments).and_return([])
        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: @kase}
        partial = clearance_levels_section(rendered).basic_details

        expect(partial.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial.dacu_disclosure.data.text).to eq 'Dack Dispirito'
      end
    end

    context 'case flagged and accepted for approval by DACU Disclosure, Press and Private offices' do
      it 'displays details of all approvers' do
        allow(@kase).to receive(:approvers).and_return([ double(User), double(User), double(User) ])
        press_office_assignment = double(Assignment)
        allow(press_office_assignment).to receive(:team).and_return(team_press_office)
        allow(press_office_assignment).to receive(:user).and_return(double User, full_name: 'Preston Offman')
        private_office_assignment = double(Assignment)
        allow(private_office_assignment).to receive(:team).and_return(team_private_office)
        allow(private_office_assignment).to receive(:user).and_return(double User, full_name: 'Primrose Offord')
        allow(@kase).to receive(:non_default_approver_assignments).and_return([ press_office_assignment, private_office_assignment ])
        render partial: 'cases/clearance_levels.html.slim',
               locals:{ case_details: @kase}
        partial = clearance_levels_section(rendered).basic_details

        expect(partial.deputy_director.data.text).to eq 'Margaret Thatcher'
        expect(partial.dacu_disclosure.data.text).to eq 'Dack Dispirito'

        approver_dets = partial.non_default_approvers[0]
        expect(approver_dets.department_name.text).to eq 'Press Office'
        expect(approver_dets.approver_name.text).to eq 'Preston Offman'

        approver_dets = partial.non_default_approvers[1]
        expect(approver_dets.department_name.text).to eq 'Private Office'
        expect(approver_dets.approver_name.text).to eq 'Primrose Offord'
      end
    end
  end

end
