require "rails_helper"

describe CaseCreateService do
  let(:manager) { create :manager, managing_teams: [ team_dacu ] }
  let!(:team_dacu) { find_or_create :team_dacu }
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:regular_params) do
    {
      requester_type: 'member_of_the_public',
      name: 'A. Member of Public',
      postal_address: '102 Petty France',
      email: 'member@public.com',
      subject: 'FOI request from controller spec',
      message: 'FOI about prisons and probation',
      received_date_dd: Time.zone.today.day.to_s,
      received_date_mm: Time.zone.today.month.to_s,
      received_date_yyyy: Time.zone.today.year.to_s,
      delivery_method: :sent_by_email,
      uploaded_request_files: ['uploads/71/request/request.pdf'],
    }
  end

  context 'unflagged FOI case' do
    let(:params) do
      regular_params.merge flag_for_disclosure_specialists: 'no'
    end
    let(:ccs) { CaseCreateService.new(manager, Case::FOI::Standard, params) }

    it 'creates a case' do
      expect { ccs.call }.to change { Case::Base.count }.by 1
    end

    it 'uses the params provided' do
      ccs.call

      created_case = Case::Base.first
      expect(created_case.requester_type).to eq 'member_of_the_public'
      expect(created_case.name).to eq 'A. Member of Public'
      expect(created_case.postal_address).to eq '102 Petty France'
      expect(created_case.email).to eq 'member@public.com'
      expect(created_case.subject).to eq 'FOI request from controller spec'
      expect(created_case.message).to eq 'FOI about prisons and probation'
      expect(created_case.received_date).to eq Time.zone.today
    end

    it 'sets the result to "assign_responder"' do
      ccs.call
      expect(ccs.result).to eq :assign_responder
    end

    it 'returns true' do
      expect(ccs.call).to eq true
    end
  end

  context 'flagged FOI case' do
    let(:params) do
      regular_params.merge flag_for_disclosure_specialists: 'yes'
    end
    let(:ccs) { CaseCreateService.new(manager, Case::FOI::Standard, params) }

    it 'creates a case' do
      expect { ccs.call }.to change { Case::Base.count }.by 1
    end

    it 'uses the params provided' do
      ccs.call

      created_case = Case::Base.first
      expect(created_case.requester_type).to eq 'member_of_the_public'
      expect(created_case.name).to eq 'A. Member of Public'
      expect(created_case.postal_address).to eq '102 Petty France'
      expect(created_case.email).to eq 'member@public.com'
      expect(created_case.subject).to eq 'FOI request from controller spec'
      expect(created_case.message).to eq 'FOI about prisons and probation'
      expect(created_case.received_date).to eq Time.zone.today
    end

    it 'flags for disclosure specialists' do
      ccs.call
      created_case = Case::Base.first
      expect(created_case.approver_assignments.first.team)
        .to eq team_dacu_disclosure
    end

    it 'sets the result to "assign_responder"' do
      ccs.call
      expect(ccs.result).to eq :assign_responder
    end

    it 'returns true' do
      expect(ccs.call).to eq true
    end
  end

  context 'ICO case' do
    let(:received)    { Date.today }
    let(:deadline)    { 1.month.from_now.beginning_of_day + 10.hours }
    let(:received) { Date.today }
    let(:deadline) { 1.month.from_now }
    let(:foi)      { create :closed_case }
    let(:params) do
      {
          # 'type'                    => 'Case::ICO::FOI',
          'original_case_id'        => foi.id,
          'ico_reference_number'    => 'ABC1344422',
          'received_date_dd'        => received.day.to_s,
          'received_date_mm'        => received.month.to_s,
          'received_date_yyyy'      => received.year.to_s,
          'external_deadline_dd'    => deadline.day.to_s,
          'external_deadline_mm'    => deadline.month.to_s,
          'external_deadline_yyyy'  => deadline.year.to_s,
          'subject'                 => 'ICO FOI deadlines',
          'message'                 => 'AAAAA'
      }
    end
    let(:ccs) { CaseCreateService.new(manager, Case::ICO::FOI, params) }
    let(:created_ico_case) { Case::ICO::FOI.last }

    it 'uses the params provided' do
      ccs.call

      expect(created_ico_case.ico_reference_number).to eq 'ABC1344422'
      expect(created_ico_case.external_deadline).to eq deadline.to_date
      expect(created_ico_case.internal_deadline).to eq(10.business_days.before(deadline).to_date)
      expect(created_ico_case.message).to eq 'AAAAA'
      expect(created_ico_case.subject).to eq 'ICO FOI deadlines'
      expect(created_ico_case.current_state).to eq 'unassigned'
    end

    it 'sets the workflow to trigger' do
      ccs.call
      expect(created_ico_case.workflow).to eq 'trigger'
    end

    it 'assigns the case to disclosure for approval' do
      ccs.call
      approving_assignments = created_ico_case.assignments.approving
      expect(approving_assignments.size).to eq 1
      assignment = approving_assignments.first
      expect(assignment.state).to eq 'pending'
      expect(assignment.team).to eq BusinessUnit.dacu_disclosure
    end
  end

  context 'invalid case params' do
    let(:params) do
      regular_params.merge name: nil
    end
    let(:ccs) { CaseCreateService.new(manager, Case::FOI::Standard, params) }

    it 'sets the result to "error"' do
      ccs.call
      expect(ccs.result).to eq :error
    end

    it 'returns false' do
      expect(ccs.call).to eq false
    end
  end

  context 'invalid case params' do
    let(:params) do
      regular_params.merge name: nil
    end
    let(:ccs) { CaseCreateService.new(manager, Case::FOI::Standard, params) }

    it 'sets the result to "error"' do
      ccs.call
      expect(ccs.result).to eq :error
    end

    it 'returns false' do
      expect(ccs.call).to eq false
    end
  end
end
