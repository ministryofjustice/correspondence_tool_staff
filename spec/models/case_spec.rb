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
#  delivery_method      :enum
#  workflow             :string
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
  let(:press_officer)      { create :press_officer }
  let(:press_office)       { press_officer.approving_team }
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

  let(:kase) { create :case }


  describe 'has a factory' do
    it 'that produces a valid object by default' do
      Timecop.freeze non_trigger_foi.received_date + 1.day do
        expect(non_trigger_foi).to be_valid
      end
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)            }
    it { should validate_presence_of(:received_date)   }
    it { should validate_presence_of(:subject)         }
    it { should validate_presence_of(:requester_type)  }
    it { should validate_presence_of(:delivery_method) }
    it { should validate_presence_of(:type)            }
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

  describe 'default_scope' do
    it "applies a default scope to exclude deleted cases" do
      expect(Case.all.to_sql).to eq Case.unscoped.where( deleted?: false).to_sql
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
      expect(Case.opened).to match_array [ open_case, responded_case ]
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

  describe 'not_with_team scope' do
    it 'returns cases that are not with a given team' do
      other_assigned_case = create :assigned_case
      expect(Case.not_with_teams(responding_team)).to match_array([other_assigned_case])
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
                                         received_date: Date.new(2017, 1, 5)
        @responded_late_case = create :responded_case,
                                      received_date: Date.new(2017, 1, 4)
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
      expect(foi.type).to eq 'Case'
    end

    it 'does validate presence of message for email foi' do
      email_foi = build :case
      email_foi.delivery_method = 'sent_by_email'
      expect(email_foi).to be_valid
      email_foi.message = nil
      expect(email_foi).not_to be_valid
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

      should have_enum(:delivery_method).
          with_values(
              [
                  'sent_by_email',
                  'sent_by_post'
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

  describe '#subject' do
    it { should validate_length_of(:subject).is_at_most(100) }
  end

  describe '#received_date' do
    let(:case_received_yesterday)   { build(:case, received_date: Date.yesterday.to_s) }
    let(:case_received_long_ago)    { build(:case, received_date: 65.days.ago) }
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
        @abs_1 = create :exemption, :absolute, name: 'Abs 1', abbreviation: 'abs1'
        @abs_2 = create :exemption, :absolute, name: 'Abs 2', abbreviation: 'abs2'
        @qual_1 = create :exemption, :qualified, name: 'Qualified 1', abbreviation: 'qual1'
        @qual_2 = create :exemption, :qualified, name: 'Qualified 2', abbreviation: 'qual2'
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

    describe 'linked_cases' do
      before(:all) do
        @case_1 = create :case
        @case_2 = create :case
        @case_3 = create :case

        #link cases
        @case_1.linked_cases << [@case_2, @case_3]
        @case_3.linked_cases << [@case_1]
      end

      it 'should show case 1 having two links' do
        expect(@case_1.linked_cases).to include @case_2 ,@case_3
        expect(@case_1.linked_cases.size).to eq 2
      end

      it 'should show case 2 having no links' do
        expect(@case_2.linked_cases).to be_empty
      end

      it 'should show case 3 having one links' do
        expect(@case_3.linked_cases).to include @case_1
        expect(@case_3.linked_cases.size).to eq 1
      end
    end

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
      Cases::FOIStateMachine.states.each do |state|
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

  describe '#team_for_user' do
    let(:responder)       { case_being_drafted_trigger.responder }
    let(:responding_team) { case_being_drafted_trigger.responding_team }
    let(:other_responder) { create :responder,
                                   responding_teams: [responding_team] }

    it 'returns the team that the user is assigned to the case from' do
      expect(case_being_drafted_trigger.team_for_user(responder))
        .to eq responding_team
    end

    it 'if the user is not assigned to the case it returns the team they have in common' do
      expect(case_being_drafted_trigger.team_for_user(other_responder))
        .to eq responding_team
    end

    it 'returns nil if there is no assignment for that user' do
      user = create :user
      expect(case_being_drafted_trigger.team_for_user(user)).to be_nil
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
      expect(case_being_drafted_trigger.transitions.size).to eq 3
      expect(case_being_drafted_trigger.transitions[0].most_recent).to be false
      expect(case_being_drafted_trigger.transitions[1].most_recent).to be false
      expect(case_being_drafted_trigger.transitions[2].most_recent).to be true
      expect(case_being_drafted_trigger.transitions.most_recent).to eq case_being_drafted_trigger.transitions[2]
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

      expect(Case.new.attachments_dir('responses', upload_group))
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

      expect(Case.new.uploads_dir('responses'))
        .to eq "this_is_not_random/responses"
    end
  end

  describe '#upload_response_groups' do
    it 'instantiates CaseUploadGroupCollection with response attachments' do
      attachments = double 'CaseAttachments for Case'
      response_attachments = double 'Response attachments'
      expect(attachments).to receive(:response).and_return(response_attachments)
      expect(kase).to receive(:attachments).and_return(attachments)
      expect(CaseAttachmentUploadGroupCollection).to receive(:new).with(kase, response_attachments)
      kase.upload_response_groups
    end
  end

  describe '#upload_request_groups' do
    it 'instantiates CaseUploadGroupCollection with request attachments' do
      attachments = double 'CaseAttachments for Case'
      request_attachments = double 'Request attachments'
      expect(attachments).to receive(:request).and_return(request_attachments)
      expect(kase).to receive(:attachments).and_return(attachments)
      expect(CaseAttachmentUploadGroupCollection).to receive(:new).with(kase, request_attachments)
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
    it 'returns case with a number that matches the query' do
      expect(Case.search(accepted_case.number)).to match_array [accepted_case]
    end
  end

  describe 'papertrail versioning', versioning: true do

    before(:each) do
      @kase = create :case, name: 'aaa', email: 'aa@moj.com', received_date: Date.today, subject: 'subject A', postal_address: '10 High Street', requester_type: 'journalist'
      @kase.update!(name: 'bbb', email: 'bb@moj.com', received_date: 1.day.ago, subject: 'subject B', postal_address: '20 Low Street', requester_type: 'offender')
    end

    it 'saves all values in the versions object hash' do
      version_hash = YAML.load(@kase.versions.last.object)
      expect(version_hash['email']).to eq 'aa@moj.com'
      expect(version_hash['received_date']).to eq Date.today
      expect(version_hash['subject']).to eq 'subject A'
      expect(version_hash['postal_address']).to eq '10 High Street'
      expect(version_hash['requester_type']).to eq 'journalist'
    end

    it 'can reconsititue a record from a version (except for received_date)' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.email).to eq 'aa@moj.com'
      expect(original_kase.subject).to eq 'subject A'
      expect(original_kase.postal_address).to eq '10 High Street'
      expect(original_kase.requester_type).to eq 'journalist'
    end

    it 'does not reconstitute the received date properly because of an interaction with govuk_date_fields' do
      original_kase = @kase.versions.last.reify
      expect(original_kase.received_date).to eq 1.day.ago.to_date
    end
  end

  describe '#add_linked_case' do
    let(:kase_1) { create :case }
    let(:kase_2) { create :case }

    describe 'creates a link between two cases' do

      it 'creates two entries in the linked case table' do
        kase_1.add_linked_case(kase_2)
        expect(kase_1.linked_cases.first.id).to eq kase_2.id
        expect(kase_2.linked_cases.first.id).to eq kase_1.id
      end

      it 'does not fail if the links already exist' do
        kase_1.add_linked_case(kase_2)
        kase_1.add_linked_case(kase_2)
        expect(kase_1.linked_cases.first.id).to eq kase_2.id
        expect(kase_2.linked_cases.first.id).to eq kase_1.id
      end

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
