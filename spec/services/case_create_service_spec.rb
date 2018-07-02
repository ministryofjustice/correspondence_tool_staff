require "rails_helper"

describe CaseCreateService do
  let(:manager) { create :manager, managing_teams: [ team_dacu ] }
  let!(:team_dacu) { find_or_create :team_dacu }
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:regular_params) do
    {
      type: 'Case::FOI::Standard',
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
