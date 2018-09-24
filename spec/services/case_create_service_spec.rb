require "rails_helper"

describe CaseCreateService do

  let(:manager) { create :manager, managing_teams: [ team_dacu ] }
  let!(:team_dacu) { find_or_create :team_dacu }
  let!(:team_dacu_disclosure) { find_or_create :team_dacu_disclosure }
  let(:regular_params) do
    ActionController::Parameters.new(
    {
        case_foi: {
          type: 'Standard',
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
          flag_for_disclosure_specialists: 'no'
          }
    })
  end

  context 'unflagged FOI case' do
    let(:params) do
      regular_params.merge flag_for_disclosure_specialists: 'no'
    end
    let(:ccs) { CaseCreateService.new(manager, 'foi', params) }

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
      regular_params['case_foi']['flag_for_disclosure_specialists'] = 'yes'
      regular_params
    end
    let(:ccs) { CaseCreateService.new(manager, 'foi', params) }

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
    let(:received)          { 0.business_days.ago }
    let(:deadline)          { 28.business_days.after(received) }
    let(:internal_deadline) { 10.business_days.before(deadline) }
    let(:foi)               { create :closed_case }
    let(:params) do
      ActionController::Parameters.new(
      { 'case_ico' => {
          'type'                    => 'Case::ICO::FOI',
          'original_case_type'      => 'FOI',
          'original_case_id'        => foi.id,
          'ico_officer_name'        => 'Ian C. Oldman',
          'ico_reference_number'    => 'ABC1344422',
          'received_date_dd'        => received.day.to_s,
          'received_date_mm'        => received.month.to_s,
          'received_date_yyyy'      => received.year.to_s,
          'external_deadline_dd'    => deadline.day.to_s,
          'external_deadline_mm'    => deadline.month.to_s,
          'external_deadline_yyyy'  => deadline.year.to_s,
          'internal_deadline_dd'    => internal_deadline.day.to_s,
          'internal_deadline_mm'    => internal_deadline.month.to_s,
          'internal_deadline_yyyy'  => internal_deadline.year.to_s,
          'message'                 => 'AAAAA'
        }
      })
    end
    let(:ccs) { CaseCreateService.new(manager, 'ico', params) }
    let(:created_ico_case) { Case::ICO::FOI.last }

    it 'uses the params provided' do
      ccs.call

      created_case = Case::Base.find(ccs.case.id)
      expect(created_case).to be_instance_of(Case::ICO::FOI)
      expect(created_ico_case.ico_officer_name).to eq 'Ian C. Oldman'
      expect(created_case.ico_reference_number).to eq 'ABC1344422'
      expect(created_case.external_deadline).to eq deadline.to_date
      expect(created_case.internal_deadline).to eq(10.business_days.before(deadline).to_date)
      expect(created_case.message).to eq 'AAAAA'
      expect(created_case.subject).to eq foi.subject
      expect(created_case.current_state).to eq 'unassigned'
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

  let(:ico_overturned_params) do
    {
      'received_date_dd'        => received.day.to_s,
      'received_date_mm'        => received.month.to_s,
      'received_date_yyyy'      => received.year.to_s,
      'external_deadline_dd'    => deadline.day.to_s,
      'external_deadline_mm'    => deadline.month.to_s,
      'external_deadline_yyyy'  => deadline.year.to_s,
      'reply_method'            => 'send_by_email',
      'email'                   => 'stephen@stephenrichards.eu',
      'postal_address'          => ''
    }
  end

  context 'OverturnedICO' do
    context 'SAR' do
      let(:received)              { Date.today }
      let(:deadline)              { 1.month.from_now.to_date }
      let(:original_ico_appeal)   { create :ico_sar_case }
      let(:original_case)         { create :sar_case }
      let(:ccs)                   { CaseCreateService.new(manager, 'overturned_sar', params) }
      let(:params) do
        ActionController::Parameters.new(
          {
            correspondence_type: 'overturned_sar',
            case_overturned_sar: ico_overturned_params.merge(
              original_ico_appeal_id: original_ico_appeal.id.to_s,
              original_case_id:       original_case.id.to_s
            ),
            commit:              'Create case',
          })
      end

      it 'creates a case with the specified params' do
        ccs.call
        kase = Case::OverturnedICO::SAR.last
        expect(kase).to be_valid
        expect(kase.original_ico_appeal).to eq original_ico_appeal
        expect(kase.original_case).to eq original_case
        expect(kase.received_date).to eq received
        expect(kase.external_deadline).to eq deadline
        expect(kase.reply_method).to eq 'send_by_email'
        expect(kase.email).to eq 'stephen@stephenrichards.eu'
      end

      it 'sets the workflow to standard' do
        ccs.call
        kase = Case::OverturnedICO::SAR.last
        expect(kase.workflow).to eq 'standard'
      end

      it 'sets the current state to unassigned' do
        ccs.call
        kase = Case::OverturnedICO::SAR.last
        expect(kase.current_state).to eq 'unassigned'
      end

      it 'sets the escalation date to 20 working days before the external deadline' do
        ccs.call
        kase = Case::OverturnedICO::SAR.last
        expect(kase.internal_deadline).to eq 20.business_days.before(kase.external_deadline)
      end

      it 'calls #link_related_cases on the newly created case' do
        expect_any_instance_of(Case::OverturnedICO::SAR).to receive(:link_related_cases)
        ccs.call
      end

      context 'invalid case type for original ico appeal' do
        let(:original_ico_appeal)   { create :case }

        it 'errors' do
          ccs.call

          expect(ccs.case.errors[:original_ico_appeal]).to eq ['is not an ICO appeal for a SAR case']
        end
      end
    end

  end

  describe '#create_params' do
    context 'ICO Overturned FOI' do
      let(:received)            { 0.business_days.ago }
      let(:deadline)            { 28.business_days.from_now }
      let(:original_ico_appeal) { create(:ico_foi_case) }
      let(:original_case)       { create(:foi_case) }
      let(:params) do
        ActionController::Parameters.new(
          {
            correspondence_type: 'overturned_foi',
            case_overturned_foi: ico_overturned_params.merge(
              original_ico_appeal_id: original_ico_appeal.id.to_s,
              original_case_id:       original_case.id.to_s
            ),
            commit:              'Create case',
          })
      end

      let(:service) { CaseCreateService.new(manager, 'overturned_foi', params) }

      it 'returns case_overturned_foi params' do
        create_params = service.__send__(:create_params, 'overturned_foi')
        expect(create_params).to eq params.require(:case_overturned_foi).permit!
      end
    end
  end

  context 'invalid case params' do
    let(:params) do
      regular_params[:case_foi][:name] = nil
      regular_params
    end
    let(:ccs) { CaseCreateService.new(manager, 'foi', params) }

    it 'sets the result to "error"' do
      ccs.call
      expect(ccs.result).to eq :error
    end

    it 'returns false' do
      expect(ccs.call).to eq false
    end
  end
end
