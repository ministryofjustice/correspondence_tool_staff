# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :integer
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#

require 'rails_helper'

RSpec.describe Case, type: :model do

  let(:general_enquiry) do
    build :case,
      received_date: Date.parse('16/11/2016'),
      category: create(:category, :gq)
  end

  let(:no_postal)          { build :case, postal_address: nil             }
  let(:no_postal_or_email) { build :case, postal_address: nil, email: nil }
  let(:no_email)           { build :case, email: nil                      }
  let(:responding_team)    { create :responding_team                      }
  let(:responder)          { responding_team.responders.first             }
  let(:coworker)           { create :responder,
                                    responding_teams: [responding_team]   }
  let(:manager)            { create :manager                              }
  let(:approving_team)     { create :approving_team                       }
  let(:non_trigger_foi)    { build :case, received_date: Date.parse('16/11/2016') }
  let(:assigned_case)      { create :assigned_case,
                                    responding_team: responding_team }
  let(:accepted_case)      { create :accepted_case,
                                    responder: responder }
  let(:case_being_drafted) { create :case_being_drafted }
  let(:case_being_drafted_flagged) { create :case_being_drafted, :flagged,
                                            approving_team: approving_team }
  let(:case_being_drafted_trigger) { create :case_being_drafted, :flagged_accepted }
  let(:trigger_foi) do
    create :case, :flagged,
           received_date: Date.parse('16/11/2016')
  end


  describe 'has a factory' do
    it 'that produces a valid object by default' do
      Timecop.freeze non_trigger_foi.received_date + 1.day do
        expect(non_trigger_foi).to be_valid
      end
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)           }
    it { should validate_presence_of(:message)        }
    it { should validate_presence_of(:received_date)  }
    it { should validate_presence_of(:subject)        }
    it { should validate_presence_of(:requester_type) }
  end

  context 'flagged for approval scopes' do
    before(:all) do
      Team.all.map(&:destroy)
      TeamsUsersRole.all.map(&:destroy)
      @team_1 = create :approving_team, name: 'DACU APPROVING 1'
      @team_2 = create :approving_team, name: 'DACU APPROVING 2'
      @unflagged = create :case, name: 'Unfagged'
      @flagged_t1 = create :case, :flagged, approving_team: @team_1, name: 'Flagged team 1'
      @flagged_t2 = create :case, :flagged, approving_team: @team_2, name: 'Flagged team 2'
      @accepted_t1 = create :case, :flagged_accepted, approving_team: @team_1, name: 'Accepted team 1'
      @accepted_t2 = create :case, :flagged_accepted, approving_team: @team_2, name: 'Accepted team 2'
    end

    after(:all) { DbHousekeeping.clean }
    #   Case.all.map(&:destroy)
    #   User.all.map(&:destroy)
    #   TeamsUsersRole.all.map(&:destroy)
    # end

    context '.flagged_for_approval' do
      context 'passed one team as a parameter' do
        it 'returns all the cases flagged for approval by the specified team' do
          expect(Case.flagged_for_approval(@team_1))
            .to match_array [ @flagged_t1, @accepted_t1 ]
        end
      end

      context 'passed an array of teams as a parameter' do
        it 'returns all the cases flagged for approval for all specified teams' do
          expect(Case.flagged_for_approval(@team_1, @team_2))
            .to match_array [
                  @flagged_t1,
                  @accepted_t1,
                  @flagged_t2,
                  @accepted_t2
                ]
        end
      end
    end

    context '.flagged_for_approval.unaccepted' do
      context 'one team passsed as a parameter' do
        it 'returns only cases flagged which HAVE NOT been accepted' do
          expect(Case.flagged_for_approval(@team_1).unaccepted)
            .to match_array [ @flagged_t1 ]
        end
      end

      context 'multiple teams passed as a parameter' do
        it 'returns only cases flagged which HAVE NOT been accepted' do
          expect(Case.flagged_for_approval(@team_2, @team_1).unaccepted)
            .to match_array [ @flagged_t1, @flagged_t2 ]
        end
      end
    end

    context '.flagged_for_approval.accepted' do
      context 'one team passsed as a parameter' do
        it 'returns only cases flagged which HAVE been accepted' do
          expect(Case.flagged_for_approval(@team_1).accepted)
            .to match_array [ @accepted_t1 ]
        end
      end

      context 'multiple teams passsed as a parameter' do
        it 'returns only cases flagged which HAVE been accepted' do
          expect(Case.flagged_for_approval(@team_1, @team_2).accepted)
            .to match_array [ @accepted_t1, @accepted_t2 ]
        end
      end
    end
  end

  describe 'open scope' do
    it 'returns only closed cases in most recently closed first' do
      Timecop.freeze 1.minute.ago
      open_case = create :case
      Timecop.freeze 2.minutes.ago
      responded_case = create :responded_case
      Timecop.return
      create :closed_case, last_transitioned_at: 2.days.ago
      create :closed_case, last_transitioned_at: 1.day.ago
      expect(Case.opened).to eq [ open_case, responded_case ]
    end
  end

  describe 'closed scope' do
    it 'returns only closed cases in most recently closed first' do
      create :case
      create :responded_case
      closed_case_1 = create :closed_case, last_transitioned_at: 2.days.ago
      closed_case_2 = create :closed_case, last_transitioned_at: 1.day.ago
      expect(Case.closed).to eq [ closed_case_2, closed_case_1 ]
    end
  end

  describe 'with_team scope' do
    it 'returns cases that are with a given team' do
      create :assigned_case # Just some other case
      expect(Case.with_teams(responding_team)).to match_array([assigned_case])
    end

    it 'can accept more than one team' do
      responding_team_b = create :responding_team
      expected_cases = [
        assigned_case,
        create(:assigned_case, responding_team: responding_team_b),
      ]
      expect(Case.with_teams([responding_team, responding_team_b]))
        .to match_array expected_cases
    end

    it 'does not include rejected assignments' do
      expected_cases = [assigned_case]
      create(:rejected_case, responding_team: responding_team)
      expect(Case.with_teams(responding_team)).to match_array(expected_cases)
    end

    it 'includes accepted cases' do
      created_cases = [assigned_case, accepted_case]
      expect(Case.with_teams(responding_team)).to match_array(created_cases)
    end
  end

  describe 'with_user scope' do
    it 'returns cases that are with a given user' do
      create :accepted_case # Just some other case
      expect(Case.with_user(responder)).to match_array([accepted_case])
    end

    it 'can accept more than one user' do
      responder_b = create :responder
      expected_cases = [
        accepted_case,
        create(:accepted_case, responder: responder),
      ]
      expect(Case.with_user(responder, responder_b))
        .to match_array expected_cases
    end

    it 'does not include rejected assignments' do
      expected_cases = [accepted_case]
      create(:rejected_case, responder: responder)
      expect(Case.with_user(responder)).to match_array(expected_cases)
    end
  end

  describe 'waiting_to_be_accepted scope' do
    it 'only returns cases that have not been accepted for team' do
      accepted_case
      expected_cases = [assigned_case]
      expect(Case.waiting_to_be_accepted(responding_team))
        .to match_array(expected_cases)
    end
  end

  describe 'most_recent_first scope' do
    let!(:case_oldest) { create :case, received_date: 11.business_days.ago }
    let!(:case_recent) { create :case, received_date: 10.business_days.ago }

    it 'orders cases by their external deadline' do
      expect(Case.most_recent_first).to eq [case_recent, case_oldest]
    end

    it 're-orders any previous ordering' do
      expect(Case.by_deadline.most_recent_first).to eq [case_recent, case_oldest]
    end
  end

  context 'with open, responded and closed cases in time and late' do
    before do
      Timecop.freeze Date.new(2017, 2, 2) do
        @open_in_time_case = create :accepted_case, received_date: Date.new(2017, 1, 5)
        @open_late_case = create :accepted_case, received_date: Date.new(2017, 1, 4)
        @responded_in_time_case = create :responded_case,
                                         received_date: Date.new(2017, 1, 3),
                                         date_responded: Date.new(2017, 1, 31)
        @responded_late_case = create :responded_case,
                                      received_date: Date.new(2017, 1, 3),
                                      date_responded: Date.new(2017, 2, 1)
        @closed_in_time_case = create :closed_case,
                                      received_date: Date.new(2017, 1, 3),
                                      date_responded: Date.new(2017, 1, 31)
        @closed_late_case = create :closed_case,
                                   received_date: Date.new(2017, 1, 3),
                                   date_responded: Date.new(2017, 2, 1)

      end
    end

    describe 'in_time scope' do
      it 'only returns cases that are not past their deadline' do
        Timecop.freeze Date.new(2017, 2, 2) do
          expect(Case.in_time).to match_array([
                                                @open_in_time_case,
                                                @responded_in_time_case,
                                                @closed_in_time_case
                                              ])
        end
      end
    end

    describe 'late scope' do
      it 'only returns cases that are past their deadline' do
        Timecop.freeze Date.new(2017, 2, 2) do
          expect(Case.late).to match_array([
                                             @open_late_case,
                                             @responded_late_case,
                                             @closed_late_case
                                           ])
        end
      end
    end
  end


  describe 'conditional validations of current state' do
    context 'new record' do
      it 'does not validate presence of current_state' do
        kase = build :case
        expect(kase.current_state).to be_nil
        expect(kase.valid?).to be true
      end

      it 'does validate presence on update' do
        kase = create :case
        kase.current_state = nil
        expect(kase).not_to be_valid
        expect(kase.errors[:current_state]).to eq ["can't be blank"]
      end
    end
  end

  describe 'enums' do
    it do
      should have_enum(:requester_type).
        with_values(
          [
            'academic_business_charity',
            'journalist',
            'member_of_the_public',
            'offender',
            'solicitor',
            'staff_judiciary',
            'what_do_they_know'
          ]
        )
    end
  end

  context 'without a postal or email address' do
    it 'is invalid' do
      expect(no_postal_or_email).not_to be_valid
    end
  end

  context 'without a postal_address' do
    it 'is valid with an email address' do
      expect(no_postal).to be_valid
    end
  end

  context 'without an email address' do
    it 'is valid with a postal address' do
      expect(no_email).to be_valid
    end
  end

  describe '#number' do
    let(:case_one)   { create(:case, received_date: Date.parse('11/01/2017')) }
    let(:case_two)   { create(:case, received_date: Date.parse('11/01/2017')) }
    let(:case_three) { create(:case, received_date: Date.parse('12/01/2017')) }
    let(:case_four)  { create(:case, received_date: Date.parse('12/01/2017')) }

    it 'is composed of the received date and an incremented suffix' do
      Timecop.freeze Date.new(2017, 1, 15) do
        expect(case_one.number).to eq   '170111001'
        expect(case_two.number).to eq   '170111002'
        expect(case_three.number).to eq '170112001'
        expect(case_four.number).to eq  '170112002'
      end
    end

    it 'cannot be set on create' do
      Timecop.freeze Date.new(2017, 1, 20) do
      expect { create(:case,
                        received_date: Date.parse('13/01/2017'),
                        number: 'f00') }.
          to raise_error StandardError, 'number is immutable'
      end
    end

    it 'cannot be modified' do
      Timecop.freeze(Date.new(2017, 1, 20)) do
        case_one.number = 1
        expect { case_one.save }.
          to raise_error StandardError, 'number is immutable'
      end
    end

    it 'must be unique' do
      Timecop.freeze(Date.new(2017, 1, 20)) do
        allow_any_instance_of(Case).
          to receive(:next_number).and_return(case_one.number)
        expect { case_two }.
          to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    it 'does not get reused' do
      Timecop.freeze(Date.new(2017, 1, 20)) do
        expect(case_one.number).to eq '170111001'
        case_one.destroy
        expect(case_two.number).to eq '170111002'
      end
    end
  end

  describe '#email' do
    it { should allow_value('foo@bar.com').for :email     }
    it { should_not allow_value('foobar.com').for :email  }
  end

  describe '#subject' do
    it { should validate_length_of(:subject).is_at_most(80) }
  end

  describe '#received_date' do
    let(:case_received_yesterday)   { build(:case, received_date: Date.yesterday.to_s) }
    let(:case_received_long_ago)   { build(:case, received_date: 65.days.ago) }
    let(:case_received_today){ build(:case, received_date: Date.today.to_s) }
    let(:case_received_tomorrow) { build(:case, received_date: (Date.today + 1.day).to_s) }

    it 'can be received in the past' do
      expect(case_received_yesterday).to be_valid
    end

    it 'can be received today' do
      expect(case_received_today).to be_valid
    end

    it 'cannot be received in the future' do
      expect(case_received_tomorrow).to_not be_valid
    end

    it 'cannot be received too far in the past' do
      expect(case_received_long_ago).to_not be_valid
      expect(case_received_long_ago.errors[:received_date]).to eq ['too far in past.']
    end

  end

  describe '#responder' do
    it { should have_one(:responder)
                  .through(:responder_assignment)
                  .source(:user) }
  end

  describe '#who_its_with' do
    let(:assigned_case) { create :assigned_case }
    let(:accepted_case) { create :accepted_case}
    let(:unassigned_case) { create :case }

    it 'is the currently assigned responder' do
      expect(assigned_case.who_its_with)
        .to eq assigned_case.responding_team.name
      expect(accepted_case.who_its_with)
        .to eq accepted_case.responding_team.name
    end

    it 'is the currently assigned to DACU' do
      expect(unassigned_case.managing_assignment.team.name).to eq 'DACU'
      expect(unassigned_case.managing_assignment.accepted?).to be true
    end
  end

  describe '#response_attachments' do
    let(:case_with_response) { create(:case_with_response)   }
    let(:responses) do
      case_with_response.attachments.select(&:response?)
    end

    it 'returns all attachments where type == "responsee"' do
      expect(case_with_response.response_attachments).to eq responses
    end
  end

  describe '#has_ncnd_exemption?' do
    it 'returns true if one of the exemptions is ncnd' do
      kase = create :closed_case, :with_ncnd_exemption
      kase.exemptions << create(:exemption)
      expect(kase.has_ncnd_exemption?).to be true
    end

    it 'returns false if none of the exemptions are ncnd' do
      kase = create :closed_case, :without_ncnd_exemption
      kase.exemptions << create(:exemption)
      expect(kase.has_ncnd_exemption?).to be false
    end
  end

  context 'preparing_for_close' do
    describe '#prepared_for_close?' do

      it 'is false on newly instantiated objects' do
        kase = Case.new
        expect(kase.prepared_for_close?).to be false
      end

      it 'is false on objects read from teh database' do
        kase = create :case
        k2 = Case.find(kase.id)
        expect(k2.prepared_for_close?).to be false
      end

      it 'is true after calling prepare_for_close' do
        kase = Case.new
        kase.prepare_for_close
        expect(kase.prepared_for_close?).to be true
      end
    end


    context 'when not closed / prepared for closed' do

      let(:kase) { create :case }

      context 'date_responded' do
        it 'is valid when not present' do
          expect(kase.date_responded).to be_blank
          expect(kase).to be_valid
        end
      end

      context 'outcome' do
        it 'is valid when not present' do
          expect(kase.outcome).to be_nil
          expect(kase).to be_valid
        end
      end

      context 'refusal_reason' do
        it 'is valid when not present' do
          expect(kase.refusal_reason).to be_blank
          expect(kase).to be_valid
        end
      end
    end
  end

  describe '#requires_exemptions' do
    it 'returns true when there is a refusal reason that requires an exemption' do
      kase = build :closed_case, :requires_exemption
      expect(kase.refusal_reason.requires_exemption?).to be true
      expect(kase.requires_exemption?).to be true
    end

    it 'returns false when there is a refusal reason that does not require an exemption' do
      kase = build :closed_case, :without_exemption
      expect(kase.refusal_reason.requires_exemption?).to be false
      expect(kase.requires_exemption?).to be false
    end

    it 'returns false if there is no refusal reason' do
      kase = build :case
      expect(kase.refusal_reason).to be_nil
      expect(kase.requires_exemption?).to be false
    end
  end

  describe 'associations' do
    describe '#category' do
      it 'is mandatory' do
        should validate_presence_of(:category)
      end

      it { should belong_to(:category) }
    end

    describe '#assignments' do
      it { should have_many(:assignments) }

      it 'when deleted, the record is destroyed' do
        kase = create :assigned_case
        # assignment = kase.responder_assignment
        expect do
          kase.responder_assignment.delete
        end.to change { Assignment.count }.by(-1)
      end
    end

    describe 'exemptions' do
      before(:all) do
        @ncnd = create :exemption, :ncnd, name: 'NCND'
        @abs_1 = create :exemption, :absolute, name: 'Abs 1'
        @abs_2 = create :exemption, :absolute, name: 'Abs 2'
        @qual_1 = create :exemption, :qualified, name: 'Qualified 1'
        @qual_2 = create :exemption, :qualified, name: 'Qualified 2'
      end

      after(:all) { CaseClosure::Metadatum.delete_all }

      describe '#exemption_ids=' do
        it 'replaces exisiting exemptions with ones specified in param hash' do
          k = create :case, exemptions: [@ncnd, @abs_1]
          k.exemption_ids = {@ncnd.id.to_s => "1", @abs_2.id.to_s => "1", @abs_1.id.to_s => "1"}
          expect(k.exemptions).to eq [@ncnd, @abs_1, @abs_2]
        end
      end

      describe '#exemption_ids' do
        it 'returns an array of exemption_ids' do
          k = create :case, exemptions: [@ncnd, @abs_1]
          expect(k.exemption_ids).to eq({@ncnd.id.to_s => '1', @abs_1.id.to_s => '1'})
        end
      end
    end

    describe '#responding_team' do
      it { should have_one(:responding_team) }
    end

    it { should have_one(:managing_assignment)
                  .class_name('Assignment') }
    it { should have_one(:managing_team)
                  .through(:managing_assignment)
                  .source(:team) }

    it { should have_one(:responder_assignment)
                  .class_name('Assignment') }
    it { should have_one(:responder)
                  .through(:responder_assignment)
                  .source(:user) }
    it { should have_one(:responding_team)
                  .through(:responder_assignment)
                  .source(:team) }

    it { should have_many(:approver_assignments)
                  .class_name('Assignment') }
    it { should have_many(:approvers)
                  .through(:approver_assignments)
                  .source(:user) }
    it { should have_many(:approving_teams)
                  .through(:approver_assignments)
                  .source(:team) }

    it { should have_many(:transitions)
                  .class_name('CaseTransition') }

    describe 'responded_transitions' do
      it { should have_many(:responded_transitions)
                    .class_name('CaseTransition') }

      it 'should list only responded transitions' do
        kase = create :closed_case
        expect(kase.responded_transitions.count).to eq 1
        expect(kase.responded_transitions.first.event).to eq 'respond'
      end
    end

    it { should have_many(:responder_history)
                  .through(:responded_transitions)
                  .source(:user) }
  end

  describe 'callbacks' do

    describe '#prevent_number_change' do
      it 'is called before_save' do
        Timecop.freeze(non_trigger_foi.received_date + 1 .day) do
          expect(non_trigger_foi).to receive(:prevent_number_change)
          non_trigger_foi.save!
        end
      end
    end

    describe '#set_deadlines' do
      let(:kase)                { build :case }
      let(:escalation_deadline) { Date.today - 1.day }
      let(:internal_deadline) { Date.today - 2.day }
      let(:external_deadline) { Date.today - 3.day }

      before do
        allow(DeadlineCalculator).to receive(:escalation_deadline).and_return(escalation_deadline)
        allow(DeadlineCalculator).to receive(:internal_deadline).and_return(internal_deadline)
        allow(DeadlineCalculator).to receive(:external_deadline).and_return(external_deadline)
      end

      it 'is called before_create' do
        expect(kase).to receive(:set_deadlines)
        kase.save!
      end

      it 'sets the deadlines deadline using DeadlineCalculator' do
        kase.__send__(:set_deadlines)
        expect(DeadlineCalculator).to have_received(:escalation_deadline).with(kase)
        expect(DeadlineCalculator).to have_received(:external_deadline).with(kase)
        expect(DeadlineCalculator).to have_received(:internal_deadline).with(kase)
        expect(kase.escalation_deadline).to eq escalation_deadline
        expect(kase.external_deadline).to eq external_deadline
        expect(kase.internal_deadline).to eq internal_deadline

      end
    end

    describe '#set_number' do
      it 'is called before_create' do
        Timecop.freeze(non_trigger_foi.received_date + 1 .day) do
          allow(non_trigger_foi).to receive(:set_number)
          non_trigger_foi.save rescue nil
          expect(non_trigger_foi).to have_received(:set_number)
        end
      end

      it 'assigns a case number number' do
        Timecop.freeze(non_trigger_foi.received_date + 1 .day) do
          expect(non_trigger_foi.number).to eq nil
          non_trigger_foi.save
          expect(non_trigger_foi.number).not_to eq nil
        end
      end
    end

    describe '#set_managing_team' do
      it 'is called in the before_create' do
        Timecop.freeze(non_trigger_foi.received_date + 1 .day) do
          allow(non_trigger_foi).to receive(:set_managing_team)
          non_trigger_foi.save rescue nil
          expect(non_trigger_foi).to have_received(:set_managing_team)
        end
      end

      it 'sets it to DACU' do
        Timecop.freeze(non_trigger_foi.received_date + 1.day) do
          non_trigger_foi.save!
          expect(non_trigger_foi.managing_team)
            .to eq Team.managing.find_by name: 'DACU'
        end
      end
    end
  end

  describe 'querying current state' do
    let(:kase)  { build(:case) }

    it 'any defined state can be used' do
      CaseStateMachine.states.each do |state|
        query = state + '?'
        expect([true, false]).to include kase.send(query)
      end
    end

    it 'other queries raise NoMethodError' do
      expect { kase.send('foo_bar_baz?')}.to raise_error(NoMethodError)
    end
  end

  describe 'requires_clearance?' do
    let(:approving_team) { create :approving_team }

    it 'returns true when there are assigned approvers' do
      kase = create :case
      kase.approving_teams = [approving_team]
      expect(kase.requires_clearance?).to eq true
    end

    it 'returns true when assigned approvers have accepted' do
      kase = create :case
      kase.approving_teams = [approving_team]
      kase.approver_assignments.each &:accepted!
      expect(kase.requires_clearance?).to eq true
    end

    it 'returns false when assigned approvers have approved' do
      kase = create :case
      kase.approving_teams = [approving_team]
      kase.approver_assignments.each &:accepted!
      kase.approver_assignments.each { |a| a.update approved: true }
      expect(kase.requires_clearance?).to eq false
    end

    it 'returns false when no approvers have been assigned' do
      kase = create :case
      expect(kase.requires_clearance?).to eq false
    end
  end

  describe 'with_teams?' do
    it 'returns true if a case is assigned to any of the given teams' do
      expect(case_being_drafted_flagged.with_teams?(approving_team)).to be_truthy
    end

    it 'returns false if a case is assigned to any of the given teams' do
      expect(case_being_drafted.with_teams?(approving_team)).to be_falsey
    end
  end

  describe 'does not require clearance' do

    let(:kase) { create :case }

    it 'returns false when requires clearance is true' do
      expect(kase).to receive(:requires_clearance?).and_return(true)
      expect(kase.does_not_require_clearance?).to be false
    end

    it 'returns true when requires clearance is false' do
      expect(kase).to receive(:requires_clearance?).and_return(false)
      expect(kase.does_not_require_clearance?).to be true
    end
  end

  # See note in case.rb about why this is commented out.
  #
  # describe 'awaiting_approver?' do
  #   it 'returns false when no approving team has been assigned' do
  #     expect(case_being_drafted.awaiting_approver?).to be_falsey
  #   end

  #   it 'returns true when an approving team has been assigned' do
  #     expect(case_being_drafted_flagged.awaiting_approver?).to eq true
  #   end

  #   it 'returns true when an approving team has accepted' do
  #     expect(case_being_drafted_trigger.awaiting_approver?).to be_falsey
  #   end
  # end
end

