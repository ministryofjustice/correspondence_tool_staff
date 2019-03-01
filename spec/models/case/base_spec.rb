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
#  delivery_method      :enum
#  workflow             :string
#  deleted              :boolean          default(FALSE)
#  info_held_status_id  :integer
#  type                 :string
#  appeal_outcome_id    :integer
#  dirty                :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe Case::Base, type: :model do

  let(:general_enquiry) do
    build :case, received_date: Date.parse('16/11/2016')
  end

  let(:responding_team)    { create :responding_team                      }
  let(:responder)          { responding_team.responders.first             }
  let(:coworker)           { create :responder,
                                    responding_teams: [responding_team]   }
  let(:manager)            { create :manager                              }
  let(:approving_team)     { create :approving_team                       }
  let(:press_officer)      { find_or_create :press_officer }
  let(:press_office)       { press_officer.approving_team }
  let(:non_trigger_foi)    { build :case, received_date: Date.parse('16/11/2016') }
  let(:assigned_case)      { create :assigned_case,
                                    responding_team: responding_team }
  let(:accepted_case)      { create :accepted_case,
                                    responder: responder }
  let(:accepted_sar)       { create :accepted_sar, responder: responder }
  let(:case_being_drafted) { create :case_being_drafted }
  let(:case_being_drafted_flagged) { create :case_being_drafted, :flagged,
                                            approving_team: approving_team }
  let(:case_being_drafted_trigger) { create :case_being_drafted, :flagged_accepted }
  let(:trigger_foi) do
    create :case, :flagged,
           received_date: Date.parse('16/11/2016')
  end
  let(:ot_ico_foi_draft)   { create :ot_ico_foi_noff_draft }
  let(:ot_ico_sar_draft)   { create :ot_ico_sar_noff_draft }
  let(:kase) { create :case }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      Timecop.freeze non_trigger_foi.received_date + 1.day do
        expect(non_trigger_foi).to be_valid
      end
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:received_date) }
    it { should validate_presence_of(:type)          }
  end

  context 'deleting' do
    it 'isnt valid without a reason' do
      expect(
        kase.tap { |k|
          k.update(deleted: true)
        }).not_to be_valid
    end

    it 'is valid with a reason' do
      expect(
        kase.tap { |k|
          k.update(deleted: true, reason_for_deletion: 'It needs to go')
        }).to be_valid
    end
  end

  describe 'workflow validation' do
    it 'validates the workflow' do
      should validate_inclusion_of(:workflow).
                in_array(%w{ standard trigger full_approval}).
                with_message('invalid')
    end
  end

  describe 'info_status_held_validation' do
    context 'active case' do
      it 'does not error if blank' do
        expect(kase.info_held_status_id).to be_blank
        expect(kase).to be_valid
      end
    end

    context 'closed_case' do
      let(:closed_case) { create :closed_case }

      context 'info_held_status is present' do
        it 'is valid' do
          expect(closed_case.info_held_status_id).to be_present
          expect(closed_case).to be_valid
        end
      end

      context 'info_held_status is absent' do
        it 'is not valid' do
          closed_case.info_held_status = nil
          expect(closed_case).not_to be_valid
          expect(closed_case.errors[:info_held_status]).to eq ["can't be blank"]
        end
      end
    end
  end

  describe 'conditional validations of message' do
    # TODO write spec 'does not validate presence of message for postal foi'

    # xit 'does not validate presence of message for postal foi' do
    #   postal_foi = build :case
    #   postal_foi.delivery_method = 'sent_by_post'
    #   # need to stub out request attachment
    #   expect(postal_foi).to be_valid
    # end

    it 'does validate presence of deafult type' do
      foi = build :case
      expect(foi.type).to eq 'Case::FOI::Standard'
    end

    it 'does validate presence of message for email foi' do
      email_foi = build :case
      email_foi.delivery_method = 'sent_by_email'
      expect(email_foi).to be_valid
      email_foi.message = nil
      expect(email_foi).not_to be_valid
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
        case_one
        allow(CaseNumberCounter).to receive(:next_for_date).and_return(1)
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

  describe '#type' do
    it { should validate_exclusion_of(:type).in_array(['Case'])
                    .with_message("Case type can't be blank")}
  end

  describe '#received_date' do
    let(:case_received_yesterday)   { build(:case, received_date: Date.yesterday.to_s) }
    let(:case_received_long_ago)    { build(:case, received_date: 370.days.ago) }
    let(:case_received_today)       { build(:case, received_date: Date.today.to_s) }
    let(:case_received_tomorrow)    { build(:case, received_date: (Date.today + 1.day).to_s) }

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

    context 'updating an old record' do
      before(:each) do
        Timecop.freeze(2.years.ago) do
          @kase = create :case
        end
      end

      context 'received date doesnt change' do
        it 'does validates ok even though received_date is out of range' do
          @kase.update(name: 'Stepriponikas  Bonstart')
          expect(@kase.received_date).to eq 2.years.ago.to_date
          expect(@kase).to be_valid
        end
      end

      context 'received date is changed' do
        it 'changes date for an out-of-range date' do
          update_result = @kase.update(name: 'Stepriponikas Bonstart', received_date: 23.months.ago)
          expect(update_result).to be false
          expect(@kase).not_to be_valid
          expect(@kase.errors[:received_date]).to eq ['too far in past.']
        end

        it 'changes for an in-range date' do
          update_result = @kase.update(name: 'Stepriponikas Bonstart', received_date: 59.days.ago)
          expect(update_result).to be true
          expect(@kase).to be_valid
        end
      end
    end
  end

  describe '#responder' do
    it { should have_one(:responder)
                  .through(:responder_assignment)
                  .source(:user) }
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

  context 'preparing_for_close' do
    describe '#prepared_for_close?' do

      it 'is false on newly instantiated objects' do
        kase = Case::Base.new
        expect(kase.prepared_for_close?).to be false
      end

      it 'is false on objects read from teh database' do
        kase = create :case
        k2 = Case::Base.find(kase.id)
        expect(k2.prepared_for_close?).to be false
      end

      it 'is true after calling prepare_for_close' do
        kase = Case::Base.new
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

  describe 'associations' do
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

    describe 'with exemption scope' do
      before(:all) do
        require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

        CaseClosure::MetadataSeeder.seed!

        @kase_1 = create_closed_case_with_exemptions('s22', 's23')          # future,  security
        @kase_2 = create_closed_case_with_exemptions('s22', 's36')          # future,  prej
        @kase_3 = create_closed_case_with_exemptions('s29', 's33', 's37')   # economy, audit, royals
      end

      it 'returns a list of cases which have the specified exemption' do
        exemption = CaseClosure::Exemption.find_by(abbreviation: 'future')
        expect(Case::Base.with_exemptions([exemption.id])).to match_array [@kase_1, @kase_2]
        expect(Case::Base.with_exemptions([exemption.id])).not_to include @kase_3
      end

      it 'returns a list of cases which have any of the specified exemptions' do
        exemption = CaseClosure::Exemption.find_by(abbreviation: 'prej')
        exemption_1 = CaseClosure::Exemption.find_by(abbreviation: 'economy')
        expect(Case::Base.with_exemptions([exemption.id, exemption_1.id])).to match_array [@kase_2, @kase_3]
        expect(Case::Base.with_exemptions([exemption.id, exemption_1.id])).not_to include @kase_1
      end

      after(:all) { DbHousekeeping.clean }


      def create_closed_case_with_exemptions(*args)
        kase = create :closed_case
        args.each do |snn|
          kase.exemptions << CaseClosure::Exemption.__send__(snn)
        end
        kase
      end
    end

    describe '#responding_team' do
      it { should have_one(:responding_team) }

      context 'responding team changed after closure' do
        it 'returns new responding team' do
          first_responding_team = create :responding_team
          last_responding_team = create :responding_team
          kase = create :closed_case, responding_team: first_responding_team
          expect(kase.responding_team).to eq first_responding_team

          assignment = kase.responder_assignment
          AssignNewTeamService.new(manager, {id: assignment.id, case_id: kase.id, team_id: last_responding_team.id }).call
          kase.reload
          expect(kase.responding_team).to eq last_responding_team
        end
      end
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
    it { should have_many(:message_transitions)
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

    it { should have_many(:users_transitions_trackers)
                  .class_name('CasesUsersTransitionsTracker') }

    it { should have_many(:case_links)
                  .class_name('LinkedCase')
                  .with_foreign_key('case_id') }

    describe 'linked_cases' do
      before(:all) do
        @case_1 = create :case
        @case_2 = create :case
        # @case_3 = create :case

        #link cases
        @case_1.linked_cases << @case_2
        # @case_3.linked_cases << [@case_1]
      end

      after(:all) { DbHousekeeping.clean }

      it 'should show case 1 to be linked to case 2' do
        expect(@case_1.linked_cases).to include @case_2
        expect(@case_1.linked_cases.size).to eq 1
      end
    end
  end

  describe 'related_cases association' do
    it { should have_many(:related_cases)
                  .through(:related_case_links)
                  .source(:linked_case) }

    it 'validates related cases' do
      linked_case = create(:case)
      allow(CaseLinkTypeValidator).to receive(:classes_can_be_linked_with_type?)
                                    .and_return(true)
      create(:case, related_cases: [linked_case])
      expect(CaseLinkTypeValidator)
        .to have_received(:classes_can_be_linked_with_type?).at_least(1).times
    end

    it 'add a type error if related case cannot be linked' do
      linked_case = create(:case)
      allow(CaseLinkTypeValidator).to receive(:classes_can_be_linked_with_type?)
                                    .and_return(false)
      kase = build(:case, related_cases: [linked_case])
      expect(kase).not_to be_valid
      expect(kase.errors[:related_cases])
        .to eq ["can't link a FOI case to a FOI as a related case"]
    end
  end

  describe 'original_appeal_and_related_cases association' do

    let(:sar)               { create :closed_sar }
    let(:linked_sar)        { create :sar_case }
    let(:manager)           { sar.managing_team.users.first }
    let(:ico_appeal)        { create :closed_ico_sar_case, :overturned_by_ico, original_case: sar }

    before(:each) do
      cls = CaseLinkingService.new(manager, sar, linked_sar.number)
      cls.create
      @ovt = create :overturned_ico_sar, original_ico_appeal: ico_appeal, original_case: sar
      @ovt.link_related_cases
      @ovt.reload
    end


    it 'returns all related cases and the original appeal' do
      expect(@ovt.original_case).to eq sar
      expect(@ovt.related_cases).to eq [linked_sar]
      expect(@ovt.original_appeal_and_related_cases).to eq [ ico_appeal, linked_sar]
    end

  end

  describe 'related_case_links association' do
    it { should have_many(:related_case_links)
                  .class_name('LinkedCase')
                  .with_foreign_key(:case_id) }
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
      let(:deadline_calculator) do
        double DeadlineCalculator::BusinessDays,
               escalation_deadline: escalation_deadline,
               internal_deadline: internal_deadline,
               external_deadline: external_deadline
      end

      before do
        allow(kase).to receive(:deadline_calculator)
                         .and_return(deadline_calculator)
      end

      it 'is called before_create' do
        expect(kase).to receive(:set_deadlines)
        kase.save!
      end

      it 'sets the deadlines deadline using DeadlineCalculator' do
        kase.__send__(:set_deadlines)
        expect(deadline_calculator).to have_received(:escalation_deadline)
        expect(deadline_calculator).to have_received(:external_deadline)
        expect(deadline_calculator).to have_received(:internal_deadline)
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

      it 'sets it to DACU BMT' do
        Timecop.freeze(non_trigger_foi.received_date + 1.day) do
          non_trigger_foi.save!
          expect(non_trigger_foi.managing_team)
            .to eq BusinessUnit.dacu_bmt
        end
      end
    end
  end

  describe 'querying current state' do
    let(:kase)  { build(:case) }

    it 'any defined state can be used' do
      ConfigurableStateMachine::Machine.states.each do |state|
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
      kase.approver_assignments.each(&:accepted!)
      expect(kase.requires_clearance?).to eq true
    end

    it 'returns false when assigned approvers have approved' do
      kase = create :case
      kase.approving_teams = [approving_team]
      kase.approver_assignments.each(&:accepted!)
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

  describe '#team_for_assigned_user' do
    let(:responder)       { case_being_drafted_trigger.responder }
    let(:responding_team) { case_being_drafted_trigger.responding_team }
    let(:other_responder) { create :responder,
                                   responding_teams: [responding_team] }

    it 'calls the TeamFinderService' do
      service = double TeamFinderService, team_for_assigned_user: nil
      expect(TeamFinderService).to receive(:new).with(kase, responder, :responder).and_return(service)
      kase.team_for_assigned_user(responder, :responder)
    end
  end

  describe '#team_for_unassigned_user' do
    let(:responder)       { case_being_drafted_trigger.responder }
    let(:responding_team) { case_being_drafted_trigger.responding_team }
    let(:other_responder) { create :responder,
                                   responding_teams: [responding_team] }

    it 'calls the TeamFinderService' do
      service = double TeamFinderService, team_for_unassigned_user: nil
      expect(TeamFinderService).to receive(:new).with(kase, responder, :responder).and_return(service)
      kase.team_for_unassigned_user(responder, :responder)
    end
  end

  describe '#approver_assignments.for_team' do

    it 'returns the correct assignments given the team' do
      case_being_drafted_trigger.assignments << Assignment.new(
        state: 'accepted',
        team_id: press_office.id,
        role: 'approving',
        user_id: press_officer.id,
        approved: false
      )
      expect(case_being_drafted_trigger.reload.approver_assignments.size).to eq 2
      presss_office_assignments = case_being_drafted_trigger.approver_assignments.for_team(press_office)
      expect(presss_office_assignments.first.team_id).to eq press_office.id
    end

    it 'returns nil if there is no such user in the assignments' do
      case_being_drafted_trigger
      new_approving_team = create :approving_team
      team_assignments = case_being_drafted_trigger.approver_assignments.for_team(new_approving_team)
      expect(team_assignments).to be_empty
    end
  end


  describe '#transitions.most_recent' do
    it 'returns the one transition that has the most recent flag set to true' do
      expect(case_being_drafted_trigger.transitions.size).to eq 4
      expect(case_being_drafted_trigger.transitions[0].most_recent).to be false
      expect(case_being_drafted_trigger.transitions[1].most_recent).to be false
      expect(case_being_drafted_trigger.transitions[2].most_recent).to be false
      expect(case_being_drafted_trigger.transitions[3].most_recent).to be true
      expect(case_being_drafted_trigger.transitions.most_recent).to eq case_being_drafted_trigger.transitions[3]
    end
  end

  describe '#flagged_for_press_office_clearance' do
    it 'returns false when not flagged by press office' do
      expect(case_being_drafted_flagged.flagged_for_press_office_clearance?).to be false
    end

    it 'returns true when flagged by press office' do
      kase = create :case_being_drafted, :flagged_accepted, :press_office
      expect(kase.flagged_for_press_office_clearance?).to be true
    end
  end

  describe '#overturned_ico' do
    it 'returns ICO Overturned FOIs and SARs cases' do
      expected_results = [ot_ico_foi_draft, ot_ico_sar_draft]
      expect(Case::Base.overturned_ico).to match_array expected_results
    end
  end

  describe 'responded?' do
    it 'returns false if there are no transitions to repsonded' do
      kase = create :case
      expect(kase.responded?).to be false
    end

    it 'returns true if there are transitions to responded' do
      kase = create :responded_case
      expect(kase.responded?).to be true
    end
  end


  describe 'responded_in_time?' do
    let(:closed_case)  { create :closed_case }

    before(:each) do
      closed_case.update!(external_deadline: 2.days.ago)
    end

    it 'returns false if there date_responded is nil' do
      kase = create :case
      expect(kase.date_responded).to be_nil
      expect(kase.responded_in_time?).to be false
    end

    it 'returns true if the date_responded is before external deadline' do
      closed_case.update!(date_responded: 3.days.ago)
      expect(closed_case.responded_in_time?).to be true
    end

    it 'returns true if the date_responded is same as external deadline' do
      closed_case.update!(date_responded: 2.days.ago)
      expect(closed_case.responded_in_time?).to be true
    end
    it 'return false if the date_responded is after the external deadline' do
      closed_case.update!(date_responded: 1.day.ago)
      expect(closed_case.responded_in_time?).to be false
    end
  end

  describe 'already_late?' do

    let(:kase) { create :case_with_response }
    it 'returns true is escalation date is in the past' do
      kase.update!(external_deadline: 1.day.ago)
      expect(kase.already_late?).to be true
    end

    it 'returns false if escalation date is today' do
      kase.update!(external_deadline: Date.today)
      expect(kase.already_late?).to be false
    end
    it 'returns false if escalation date in in the future' do
      kase.update!(external_deadline: 1.day.from_now)
      expect(kase.already_late?).to be false
    end

  end

  describe '#attachments_dir' do
    let(:upload_group) { Time.now.strftime('%Y%m%d%H%M%S') }

    it 'returns a path generated from case attributes' do
      expect(case_being_drafted.attachments_dir('responses', upload_group))
        .to eq "#{case_being_drafted.id}/responses/#{upload_group}"
    end

    it 'uses random string for the id when case is not persisted' do
      allow(SecureRandom).to receive(:urlsafe_base64)
                               .and_return('this_is_not_random')

      expect(Case::Base.new.attachments_dir('responses', upload_group))
        .to eq "this_is_not_random/responses/#{upload_group}"
    end
  end

  describe '#uploads_dir' do
    it 'returns a path generated from case attributes' do
      expect(case_being_drafted.uploads_dir('responses'))
        .to eq "#{case_being_drafted.id}/responses"
    end

    it 'uses random string for the id when case is not persisted' do
      allow(SecureRandom).to receive(:urlsafe_base64)
                               .and_return('this_is_not_random')

      expect(Case::Base.new.uploads_dir('responses'))
        .to eq "this_is_not_random/responses"
    end
  end

  describe '#upload_response_groups' do
    it 'instantiates CaseUploadGroupCollection with response attachments' do
      attachments = double 'CaseAttachments for Case'
      response_attachments = double 'Response attachments'
      expect(attachments).to receive(:response).and_return(response_attachments)
      expect(kase).to receive(:attachments).and_return(attachments)
      expect(CaseAttachmentUploadGroupCollection).to receive(:new).with(kase, response_attachments, :responder)
      kase.upload_response_groups
    end
  end

  describe '#upload_request_groups' do
    it 'instantiates CaseUploadGroupCollection with request attachments' do
      attachments = double 'CaseAttachments for Case'
      request_attachments = double 'Request attachments'
      expect(attachments).to receive(:request).and_return(request_attachments)
      expect(kase).to receive(:attachments).and_return(attachments)
      expect(CaseAttachmentUploadGroupCollection).to receive(:new).with(kase, request_attachments, :manager)
      kase.upload_request_groups
    end
  end

  describe '#current_team_and_user' do
    it 'calls the CurrentTeamAndUserService' do
      ctaus = double CurrentTeamAndUserService
      expect(CurrentTeamAndUserService).to receive(:new).with(accepted_case).and_return(ctaus)
      expect(accepted_case.current_team_and_user).to eq ctaus
    end
  end

  describe '#default_team_service' do
    context 'first call' do
      it 'instantiates a DefaultTeamService object' do
        expect(DefaultTeamService).to receive(:new).with(accepted_case).and_call_original
        dts = accepted_case.default_team_service
        expect(dts).to be_instance_of(DefaultTeamService)
      end
    end

    context 'subsequent_calls' do
      before(:each) do
        @dts = accepted_case.default_team_service
      end

      it 'uses cached version and does not instantiate new DefaultTeamSErvice' do
        expect(DefaultTeamService).not_to receive(:new)
        dts = accepted_case.default_team_service
        expect(dts).to eq @dts
      end
    end
  end

  describe '#approver_assignment_for(team)' do

    let(:team_dacu_disclosure)  { find_or_create :team_dacu_disclosure }
    let(:pending_dacu_clearance_case) { create(:pending_dacu_clearance_case) }

    context 'no approver assignments' do
      it 'returns nil' do
        expect(kase.approver_assignment_for(team_dacu_disclosure)).to be_nil
      end
    end

    context 'approver assignments but none for specified team' do

      let(:pending_dacu_clearance_case) { create(:pending_dacu_clearance_case) }

      it 'returns nil' do
        expect(pending_dacu_clearance_case.approver_assignments.any?).to be true
        team = create :team
        expect(pending_dacu_clearance_case.approver_assignment_for(team)).to be_nil
      end
    end

    context 'approver assignments including one for team' do
      it 'returns the assignment' do
        team = pending_dacu_clearance_case.approver_assignments.first.team
        assignment = pending_dacu_clearance_case.approver_assignment_for(team)
        expect(assignment.team).to eq team
      end
    end
  end

  describe 'non_default_approver_assignments' do

    let(:pending_dacu_clearance_case) { create(:pending_dacu_clearance_case) }

    context 'no approver assignments' do
      it 'returns empty array' do
        expect(kase.non_default_approver_assignments).to be_empty
      end
    end

    context 'only default clearance team approver assignment' do
      it 'returns empty array' do
        expect(pending_dacu_clearance_case.non_default_approver_assignments).to be_empty
      end
    end

    context 'multiple apprval assignments' do
      it 'returns all of them accept the default approval team assignment' do
        pending_private_clearance_case = create :pending_private_clearance_case
        private_office = find_or_create(:team_private_office)
        press_office = find_or_create(:team_press_office)
        non_default_approver_assignments = pending_private_clearance_case.non_default_approver_assignments
        expect(non_default_approver_assignments.map(&:team)).to match_array [ private_office, press_office]
      end
    end
  end

  describe '#transition_tracker_for_user' do
    it 'returns the tracker for the given user' do
      tracker = CasesUsersTransitionsTracker.create case_id: kase.id,
                                                    user_id: responder.id
      expect(kase.transition_tracker_for_user(responder)).to eq tracker
    end
  end

  describe '#sync_transition_tracker_for_user' do
    it 'calls CasesUsersTransitionsTracker.sync_for_case_and_user' do
      allow(CasesUsersTransitionsTracker).to receive(:sync_for_case_and_user)
      kase.sync_transition_tracker_for_user(responder)
      expect(CasesUsersTransitionsTracker)
        .to have_received(:sync_for_case_and_user).with(kase, responder)
    end
  end

  describe 'search' do
    before :all do
      @responding_team_a = create :responding_team, name: 'Accrediting Aptitudes'
      @responding_team_b = create :responding_team, name: 'Bargain Basement'
      @case_a = create :case_being_drafted,
                       subject: 'airplanes',
                       message: 'adulating aircraft aficionados',
                       name: 'Al Atoll',
                       responding_team: @responding_team_a,
                       responder: @responding_team_a.responders.first
      @case_b = create :case_being_drafted,
                       subject: 'brownies',
                       message: 'bonafide baked baskers',
                       name: 'Brian Bush',
                       responding_team: @responding_team_b,
                       responder: @responding_team_b.responders.first
      @sar_case = create :sar_case,
                         subject_full_name: 'Stepriponikas Bonstart',
                         name: 'Boris Johnson'
      @case_a.update_index
      @case_b.update_index
      @sar_case.update_index
    end

    after :all do
      DbHousekeeping.clean
    end

    it 'returns case with a number that matches the query' do
      expect(Case::Base.search(@case_a.number)).to match_array [@case_a]
    end

    it 'returns case with a subject that matches the query' do
      expect(Case::Base.search('airplane')).to match_array [@case_a]
    end

    it 'returns case with a message that matches the query' do
      expect(Case::Base.search('basker')).to match_array [@case_b]
    end

    it 'returns case with a requester name that matches the query' do
      expect(Case::Base.search('atoll')).to match_array [@case_a]
    end

    it 'returns case with a responding team that matches the query' do
      expect(Case::Base.search('bargain')).to match_array [@case_b]
    end

    it 'returns a SAR case with a data subject name matching the query' do
      expect(Case::Base.search('Bonstart')).to match_array [@sar_case]
    end

    it 'returns a SAR case with a requestor name matching the query' do
      expect(Case::Base.search('Boris')).to match_array [@sar_case]
    end
  end

  context 'updating deadlines after updates' do
    context 'received_date is updated' do
      context 'case has not been extended for pit' do
        it 'changes the internal and external deadlines (but not escalation deadline)' do
          kase = nil
          Timecop.freeze(Time.local(2017, 12, 1, 12, 0, 0)) do
            kase = create :case, :flagged, received_date: Date.today, created_at: Time.now
          end
          expect(kase.received_date).to eq Date.new(2017, 12, 1)
          expect(kase.external_deadline).to eq Date.new(2018, 1, 3)
          expect(kase.internal_deadline).to eq Date.new(2017, 12, 15)
          expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)

          Timecop.freeze(Time.local(2017, 11, 23, 13, 13, 56)) do
            kase.update!(received_date: Date.today)
          end
          expect(kase.received_date).to eq Date.new(2017, 11, 23)
          expect(kase.external_deadline).to eq Date.new(2017, 12, 21)
          expect(kase.internal_deadline).to eq Date.new(2017, 12, 07)
          expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)
        end
      end

      # TODO (Mohammed Seedat): An approver for a case_being_drafted in trigger
      # workflow cannot extend_for_pit. This test works because
      # CaseExtendForPITService executes the state transition setting
      # acting_team = BusinessUnit.dacu_bmt
      context 'case has been extended for pit' do
        it 'does not update deadlines' do
          approver = find_or_create :disclosure_specialist
          kase = nil

          Timecop.freeze(Time.local(2017, 12, 1, 12, 0, 0)) do
            kase = create :case_being_drafted,
              :flagged_accepted,
              approver: approver,
              received_date: Date.today,
              created_at: DateTime.now

            CaseExtendForPITService.new(
              approver,
              kase,
              kase.external_deadline + 15.days,
              'Testing updates'
            ).call
          end

          expect(kase.received_date).to       eq Date.new(2017, 12, 1)
          expect(kase.external_deadline).to   eq Date.new(2018, 1, 18)
          expect(kase.internal_deadline).to   eq Date.new(2017, 12, 15)
          expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)

          Timecop.freeze(Time.local(2017, 11, 23, 13, 13, 56)) do
            kase.update!(received_date: Date.today)
          end

          expect(kase.received_date).to       eq Date.new(2017, 11, 23)
          expect(kase.external_deadline).to   eq Date.new(2018, 1, 18)
          expect(kase.internal_deadline).to   eq Date.new(2017, 12, 15)
          expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)
        end
      end
    end

    context 'received_date is not updated' do
      it 'does not update deadlines' do
        kase = nil
        Timecop.freeze(Time.local(2017, 12, 1, 12, 0, 0)) do
          kase = create :case, :flagged, received_date: Date.today, created_at: Time.now
        end
        expect(kase.received_date).to eq Date.new(2017, 12, 1)
        expect(kase.external_deadline).to eq Date.new(2018, 1, 3)
        expect(kase.internal_deadline).to eq Date.new(2017, 12, 15)
        expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)

        Timecop.freeze(Time.local(2017, 11, 23, 13, 13, 56)) do
          kase.update!(email: 'mg@moj.gov')
        end
        expect(kase.received_date).to eq Date.new(2017, 12, 1)
        expect(kase.external_deadline).to eq Date.new(2018, 1, 3)
        expect(kase.internal_deadline).to eq Date.new(2017, 12, 15)
        expect(kase.escalation_deadline).to eq Date.new(2017, 12, 6)
      end
    end
  end

  describe '#responded_in_time_for_stats_purposes' do

    let(:responding_team_1)     { create :responding_team }
    let(:responding_team_2)     { create :responding_team }
    let(:bmt_team)              { find_or_create :team_dacu }
    let(:disclosure_team)       { find_or_create :team_dacu_disclosure }
    let(:press_office_team)     { find_or_create :team_press_office }
    let(:private_office_team)   { find_or_create :team_private_office }

    #rubocop:disable Metrics/ParameterLists
    def create_transition(kase, event, to_state, acting_team, target_team = nil, target_user = nil)
      kase.transitions << CaseTransition.new(
        event: event,
        to_state: to_state,
        metadata: {},
        sort_key: kase.transitions.empty? ? 10 : kase.transitions.maximum(:sort_key) + 10,
        most_recent: false,
        acting_user_id: acting_team.users.first.id,
        acting_team_id: acting_team.id,
        target_user_id: target_user&.id,
        target_team_id: target_team&.id)
    end
    #rubocop:enable Metrics/ParameterLists

    def create_case(t, creating_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        kase = create :case
        create_transition(kase, 'flag_for_clearance', 'unassigned', creating_team )
        kase
      end
    end

    def assign_to_responder(kase, t, acting_team, target_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'assign_responder', 'awaiting_responder', acting_team, target_team)
      end
    end

    def reject_assignment(kase, t, acting_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'reject_responder_assignment', 'unassigned', acting_team)
      end
    end

    def accept_assignment(kase, t, acting_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'accept_responder_assignment', 'drafting', acting_team)
      end
    end

    def flag_for_clearance(kase, t, acting_team, target_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'flag_for_clearance', kase.current_state, acting_team, target_team)
        kase.assignments << Assignment.new(
          state: 'accepted',
          team_id: target_team.id,
          role: 'approving',
          user_id: target_team.users.first.id,
          approved: false)
      end
    end

    def upload_response(kase, t, acting_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'add_responses', 'pending_dacu_clearance', acting_team)
      end
    end

    def request_amends(kase, t, acting_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'upload_response_and_return_for_redraft', 'drafting', acting_team)
      end
    end

    def clear_case(kase, t, new_state, acting_team)
      Timecop.freeze(Time.at(Time.parse(t))) do
        create_transition(kase, 'approve', new_state, acting_team)
      end
    end

    context 'out of time' do
      it 'returns false' do
        # responding team 2 assigned on 5 Sep, Disclosure approves response on 20 Sep
        kase = create_case '2017-09-01 13:45:22', bmt_team
        assign_to_responder(kase, '2017-09-02 10:33:01', bmt_team, responding_team_1)
        flag_for_clearance(kase, '2017-09-01 13:48:12', bmt_team, disclosure_team)
        reject_assignment(kase, '2017-09-03 09:13:44', responding_team_1)
        assign_to_responder(kase, '2017-09-03 12:43:04', bmt_team, responding_team_2)
        accept_assignment(kase, '2017-09-05 12:02:04', responding_team_2)
        upload_response(kase, '2017-09-14 15:33:01', responding_team_2)
        request_amends(kase, '2017-09-14 17:45:22', disclosure_team)
        upload_response(kase, '2017-09-19 10:33:44', responding_team_2)
        clear_case(kase, '2017-09-20 14:37:24', 'pending_press_office_clearance', disclosure_team)
        clear_case(kase, '2017-09-21 11:17:44', 'pending_private_office_clearance', press_office_team)
        clear_case(kase, '2017-09-21 11:17:44', 'awaiting_dispatch', private_office_team)
        expect(kase.responded_in_time_for_stats_purposes?).to be false
      end
    end

    context 'responding_team_2 is in time' do
      it 'returns true' do
        # responding team 2 assigned on 5 Sep, Disclosure approves response on 18 Sept
        kase = create_case '2017-09-01 13:45:22', bmt_team
        assign_to_responder(kase, '2017-09-02 10:33:01', bmt_team, responding_team_1)
        flag_for_clearance(kase, '2017-09-01 13:48:12', bmt_team, disclosure_team)
        reject_assignment(kase, '2017-09-03 09:13:44', responding_team_1)
        assign_to_responder(kase, '2017-09-05 12:43:04', bmt_team, responding_team_2)
        accept_assignment(kase, '2017-09-05 13:02:04', responding_team_2)
        upload_response(kase, '2017-09-14 15:33:01', responding_team_2)
        request_amends(kase, '2017-09-14 17:45:22', disclosure_team)
        upload_response(kase, '2017-09-18 10:33:44', responding_team_2)
        clear_case(kase, '2017-09-18 14:37:24', 'pending_press_office_clearance', disclosure_team)
        clear_case(kase, '2017-09-21 11:17:44', 'pending_private_office_clearance', press_office_team)
        clear_case(kase, '2017-09-21 11:17:44', 'awaiting_dispatch', private_office_team)
        expect(kase.responded_in_time_for_stats_purposes?).to be true
      end
    end
  end

  describe '#type_abbreviation' do
    it 'returns the class-defined type abbreviation' do
      expect(kase.type_abbreviation).to eq 'FOI'
    end
  end

  describe '#correspondence_type' do
    it 'retrieves a correspondence_type object' do
      expect(kase.correspondence_type).to eq CorrespondenceType.foi
    end

    it 'only finds the correspondence_type once' do
      foi = CorrespondenceType.foi
      allow(CorrespondenceType).to receive(:find_by!).and_return(foi)
      kase.correspondence_type
      kase.correspondence_type
      expect(CorrespondenceType).to have_received(:find_by!).at_least(1)
    end
  end

  describe '#correspondence_type_for_business_unit_assignment' do
    it 'returns the correspondence_type' do
      expect(kase.correspondence_type).to eq CorrespondenceType.foi
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

  describe 'is_foi?' do
    it 'returns true if the case if a standard FOI' do
      expect(create(:foi_case).is_foi?).to eq true
    end

    it 'returns true if the case if an FOI Compliance Review' do
      expect(create(:compliance_review).is_foi?).to eq true
    end

    it 'returns true if the case if an FOI Timeliness Review' do
      expect(create(:timeliness_review).is_foi?).to eq true
    end

    it 'returns false if the case s a SAR' do
      expect(create(:sar_case).is_foi?).to eq false
    end
  end

  describe 'is_sar?' do
    it 'returns false if the case if a standard FOI' do
      expect(create(:foi_case).is_sar?).to eq false
    end

    it 'returns false if the case if an FOI Compliance Review' do
      expect(create(:compliance_review).is_sar?).to eq false
    end

    it 'returns false if the case if an FOI Timeliness Review' do
      expect(create(:timeliness_review).is_sar?).to eq false
    end

    it 'returns true if the case if a SAR' do
      expect(create(:sar_case).is_sar?).to eq true
    end
  end

  describe '#deadline_calculator' do
    context 'FOI correspondence type' do
      let(:kase) { build_stubbed :foi_case }

      it 'returns business days calculator' do
        deadline_calculator = kase.deadline_calculator
        expect(deadline_calculator)
          .to be_an_instance_of DeadlineCalculator::BusinessDays
        expect(deadline_calculator.kase).to eq kase
      end
    end

    context 'SAR correspondence type' do
      let(:kase) { build_stubbed :sar_case }

      it 'returns business days calculator' do
        deadline_calculator = kase.deadline_calculator
        expect(deadline_calculator)
          .to be_an_instance_of DeadlineCalculator::CalendarDays
        expect(deadline_calculator.kase).to eq kase
      end
    end
  end

  describe '#mark_as_clean!' do
    it 'unsets the dirty flag' do
      kase = create :case
      expect(kase).to be_dirty
      kase.mark_as_clean!
      expect(kase).not_to be_dirty
    end
  end


  describe '#trigger_reindexing' do
    context 'creating a new record' do

      let(:kase)  { build :case }

      it 'sets the dirty flag' do
        expect(kase).not_to be_dirty
        kase.save!
        expect(kase).to be_dirty
      end

      it 'queues the job' do
        t = Time.now
        expect {
          Timecop.freeze(t) do
            kase.save!
          end
        }.to have_enqueued_job(SearchIndexUpdaterJob).at(t + 10.seconds)
      end
    end

    context 'updating an existing record' do
      let(:kase)  { create :case, :clean }

      context 'fields requiring search reindex not updated' do
        it 'does not set the dirty flag' do
          kase.update(date_responded: Date.today, workflow: 'trigger')
          expect(kase).not_to be_dirty
        end

        it 'does not queue the job' do
          kase            # need this here so that the job triggered by create is outside the expect block
          expect {
            kase.update(date_responded: Date.today, workflow: 'trigger')
          }.not_to have_enqueued_job(SearchIndexUpdaterJob)
        end
      end

      context 'fields requiring search reindexing are updated' do
        it 'sets the dirty flag' do
          kase.update(name: 'John Smith')
          expect(kase).to be_dirty
        end

        it 'queues the job' do
          kase   # need this here so that the job triggered by create is outside the expect block
          t = Time.now
          expect {
            Timecop.freeze(t) do
              kase.update(name: 'John Smith')
            end
          }.to have_enqueued_job(SearchIndexUpdaterJob).at(t + 10.seconds)
        end
      end
    end
  end

  describe '#assigned_disclosure_specialist' do
    it 'returns the specialist' do
      disclosure_specialist = find_or_create :disclosure_specialist
      kase = create :assigned_case, :flagged_accepted, approver: disclosure_specialist

      expect(kase.assigned_disclosure_specialist).to eq disclosure_specialist
    end
  end

  describe '#assigned_press_officer' do
    it 'returns the press_officer' do
      press_officer = find_or_create :press_officer
      kase = create :assigned_case, :taken_on_by_press

      expect(kase.assigned_press_officer).to eq press_officer
    end
  end

  describe '#assigned_private_officer' do
    it 'returns the private_officer' do

      private_officer = find_or_create :private_officer
      kase = create :assigned_case, :taken_on_by_private

      expect(kase.assigned_private_officer).to eq private_officer
    end
  end

  describe '#requires_flag_for_disclosure_specialists?' do
    it 'returns true' do
      expect(kase.requires_flag_for_disclosure_specialists?).to be true
    end
  end

  describe '#to_csv' do
    it 'delegates to CSVExporter' do
      kase = build :assigned_case
      exporter = double(CSVExporter)
      expect(CSVExporter).to receive(:new).with(kase).and_return(exporter)
      expect(exporter).to receive(:to_csv)

      kase.to_csv
    end
  end

  describe '#has_pit_extension?' do
    context 'any case' do
      it 'returns false by default' do
        kase = create :case_being_drafted
        expect(kase.has_pit_extension?).to be false
      end
    end

    context 'case with pit extenstion' do
      it 'returns true' do
        kase = create :case_being_drafted, :extended_for_pit
        expect(kase.has_pit_extension?).to be true
      end
    end

    context 'case with removed pit extension' do
      it 'returns false' do
        kase = create :case_being_drafted, :pit_extension_removed
        expect(kase.has_pit_extension?).to be false
      end
    end
  end


  describe '#responded_late?' do
    context 'date responded is nil' do
      it 'is false' do
        kase = find_or_create :foi_case
        expect(kase.date_responded).to be_nil
        expect(kase.responded_late?).to be false
      end
    end

    context 'date responded is present' do
      let(:kase)    { find_or_create :closed_case, date_responded: Date.today }

      context 'date responded > external deadline' do
        it 'is true' do
          kase.external_deadline = Date.yesterday
          expect(kase.responded_late?).to be true
        end
      end

      context 'date responded < external deadline' do
        it 'is false' do
          kase.external_deadline = Date.tomorrow
          expect(kase.responded_late?).to be false
        end
      end
      context 'date_responded = external deadline' do
        it 'is false' do
          kase.external_deadline = Date.today
          expect(kase.responded_late?).to be false
        end
      end
    end
  end
end
