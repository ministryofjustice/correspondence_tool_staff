# == Schema Information
#
# Table name: cases
#
#  id                :integer          not null, primary key
#  name              :string
#  email             :string
#  message           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  category_id       :integer
#  received_date     :date
#  postal_address    :string
#  subject           :string
#  properties        :jsonb
#  requester_type    :enum
#  number            :string           not null
#  date_responded    :date
#  outcome_id        :integer
#  refusal_reason_id :integer
#

require 'rails_helper'

RSpec.describe Case, type: :model do

  let(:non_trigger_foi) { build :case, received_date: Date.parse('16/11/2016') }

  let(:trigger_foi) do
    build :case,
      received_date: Date.parse('16/11/2016'),
      properties: { trigger: true }
  end

  let(:general_enquiry) do
    build :case,
      received_date: Date.parse('16/11/2016'),
      category: create(:category, :gq)
  end

  let(:no_postal)          { build :case, postal_address: nil             }
  let(:no_postal_or_email) { build :case, postal_address: nil, email: nil }
  let(:no_email)           { build :case, email: nil                      }
  let(:responder)          { create :responder                            }
  let(:manager)            { create :manager                              }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(non_trigger_foi).to be_valid
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)           }
    it { should validate_presence_of(:message)        }
    it { should validate_presence_of(:received_date)  }
    it { should validate_presence_of(:subject)        }
    it { should validate_presence_of(:requester_type) }
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
      expect(case_one.number).to eq   '170111001'
      expect(case_two.number).to eq   '170111002'
      expect(case_three.number).to eq '170112001'
      expect(case_four.number).to eq  '170112002'
    end

    it 'cannot be set on create' do
      expect { create(:case,
                      received_date: Date.parse('13/01/2017'),
                      number: 'f00') }.
        to raise_error StandardError, 'number is immutable'
    end

    it 'cannot be modified' do
      case_one.number = 1
      expect { case_one.save }.
        to raise_error StandardError, 'number is immutable'
    end

    it 'must be unique' do
      allow_any_instance_of(Case).
        to receive(:next_number).and_return(case_one.number)
      expect { case_two }.
        to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'does not get reused' do
      expect(case_one.number).to eq '170111001'
      case_one.destroy
      expect(case_two.number).to eq '170111002'
    end
  end

  describe '#email' do
    it { should allow_value('foo@bar.com').for :email     }
    it { should_not allow_value('foobar.com').for :email  }
  end

  # describe '#state' do
  #   it 'defaults to "submitted"' do
  #     expect(non_trigger_foi.state).to eq 'submitted'
  #   end
  # end

  describe '#subject' do
    it { should validate_length_of(:subject).is_at_most(80) }
  end

  describe '#received_date' do
    let(:case_received_yesterday)   { build(:case, received_date: Date.yesterday.to_s) }
    let(:case_received_today){ build(:case, received_date: Date.today.to_s) }
    let(:case_received_tomorrow) { build(:case, received_date: Date.tomorrow.to_s) }

    it 'can be received in the past' do
      expect(case_received_yesterday).to be_valid
    end

    it 'can be received today' do
      expect(case_received_today).to be_valid
    end

    it 'cannot be received in the future' do
      expect(case_received_tomorrow).to_not be_valid
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
      expect(unassigned_case.who_its_with).to eq 'DACU'
    end
  end

  describe '#responder_assignment' do
    it { should have_one(:responder_assignment).class_name('Assignment') }
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

    it { should have_one(:responder_assignment)
                  .conditions(role: 'responding')
                  .class_name('Assignment') }
    it { should have_one(:responder)
                  .through(:responder_assignment)
                  .source(:user) }
    it { should have_one(:responding_team)
                  .through(:responder_assignment)
                  .source(:team) }

    it { should have_one(:managing_assignment)
                  .conditions(role: 'managing')
                  .class_name('Assignment') }
    it { should have_one(:managing_team)
                  .through(:managing_assignment)
                  .source(:team) }
  end

  describe '#remove_response' do

    let(:kase) { create :case_with_response }
    let(:attachment) { kase.attachments.first }
    let(:assigner_id)   { 666 }

    context 'only one attachemnt' do
      before(:each) do
        allow(attachment).to receive(:remove_from_storage_bucket)
      end

      it 'removes the attachment' do
        expect(kase.attachments.size).to eq 1
        kase.remove_response(responder, attachment)
        expect(kase.attachments.size).to eq 0
      end

      it 'changes the state to drafting' do
        expect(kase.current_state).to eq 'awaiting_dispatch'
        kase.remove_response(responder, attachment)
        expect(kase.current_state).to eq 'drafting'
      end
    end

    context 'two attachments' do
      before(:each) do
        kase.attachments << build(:correspondence_response, type: 'response')
        allow(attachment).to receive(:remove_from_storage_bucket)
      end

      it 'removes one attachment' do
        expect(kase.attachments.size).to eq 2
        kase.remove_response(responder, attachment)
        expect(kase.attachments.size).to eq 1
      end

      it 'does not change the state' do
        expect(kase.current_state).to eq 'awaiting_dispatch'
        kase.remove_response(responder, attachment)
        expect(kase.current_state).to eq 'awaiting_dispatch'
      end
    end
  end

  describe 'callbacks' do

    describe '#prevent_number_change' do
      it 'is called before_save' do
        expect(non_trigger_foi).to receive(:prevent_number_change)
        non_trigger_foi.save!
      end
    end

    describe '#set_deadlines' do
      it 'is called before_create' do
        expect(non_trigger_foi).to receive(:set_deadlines)
        non_trigger_foi.save!
      end

      it 'is called after_update' do
        expect(non_trigger_foi).to receive(:set_deadlines)
        non_trigger_foi.update(category: Category.first)
      end

      it 'sets the escalation deadline for non_trigger_foi' do
        expect(non_trigger_foi.escalation_deadline).to eq nil
        non_trigger_foi.save!
        expect(non_trigger_foi.escalation_deadline.strftime("%d/%m/%y")).to eq "24/11/16"
      end

      it 'does not set the escalation deadline for trigger_foi' do
        expect(trigger_foi.escalation_deadline).to eq nil
        trigger_foi.save!
        expect(trigger_foi.escalation_deadline).to eq nil
      end

      it 'does not set the escalation deadline for general_enquiry' do
        expect(general_enquiry.escalation_deadline).to eq nil
        general_enquiry.save!
        expect(general_enquiry.escalation_deadline).to eq nil
      end

      it 'sets the internal deadline for trigger_foi' do
        expect(trigger_foi.internal_deadline).to eq nil
        trigger_foi.save!
        expect(trigger_foi.internal_deadline.strftime("%d/%m/%y")).to eq "30/11/16"
      end

      it 'sets the internal deadline for general enquiries' do
        expect(general_enquiry.internal_deadline).to eq nil
        general_enquiry.save!
        expect(general_enquiry.internal_deadline.strftime("%d/%m/%y")).to eq "30/11/16"
      end

      it 'does not set the internal_deadline for non_trigger_foi' do
        expect(non_trigger_foi.internal_deadline).to eq nil
        non_trigger_foi.save!
        expect(non_trigger_foi.internal_deadline).to eq nil
      end

      it 'sets the external deadline for all cases' do
        [non_trigger_foi, trigger_foi, general_enquiry].each do |kase|
          expect(kase.external_deadline).to eq nil
          kase.save!
          expect(kase.external_deadline.strftime("%d/%m/%y")).not_to eq nil
        end
      end
    end

    describe '#set_number' do
      it 'is called before_create' do
        allow(non_trigger_foi).to receive(:set_number)
        non_trigger_foi.save rescue nil
        expect(non_trigger_foi).to have_received(:set_number)
      end

      it 'assigns a case number number' do
        expect(non_trigger_foi.number).to eq nil
        non_trigger_foi.save
        expect(non_trigger_foi.number).not_to eq nil
      end
    end

    describe '#set_managing_team' do
      it 'is called in the before_create' do
        allow(non_trigger_foi).to receive(:set_managing_team)
        non_trigger_foi.save rescue nil
        expect(non_trigger_foi).to have_received(:set_managing_team)
      end

      it 'sets it to DACU' do
        non_trigger_foi.save!
        expect(non_trigger_foi.managing_team)
          .to eq Team.managing.find_by name: 'DACU'
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

  describe 'state machine' do
    let(:kase) { create :case }

    describe '#state_machine' do
      subject { kase.state_machine }

      it { should be_an_instance_of(CaseStateMachine) }
      it { should have_attributes(object: kase)}
    end

    describe '#assign_responder' do
      let(:unassigned_case) { create :case }
      let(:managing_team)   { create :managing_team }
      let(:manager)         { managing_team.managers.first }
      let(:responding_team) { create :responding_team }

      before do
        allow(unassigned_case.state_machine).to receive(:assign_responder)
      end

      it 'creates an assign_responder transition' do
        unassigned_case.assign_responder manager, responding_team
        expect(unassigned_case.state_machine)
          .to have_received(:assign_responder)
                .with manager,
                      managing_team,
                      responding_team
      end
    end

    describe '#responder_assignment_rejected' do
      let(:assigned_case)   { create :assigned_case }
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }
      let(:message)         { |example| "test #{example.description}" }

      before do
        allow(state_machine).to receive(:reject_responder_assignment)
        allow(state_machine).to receive(:reject_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.
          responder_assignment_rejected(responder, responding_team, message)
        expect(state_machine).to have_received(:reject_responder_assignment!).
                                   with(responder, responding_team, message)
        expect(state_machine).
          not_to have_received(:reject_responder_assignment)
      end
    end

    describe '#responder_assignment_accepted' do
      let(:assigned_case)   { create :assigned_case }
      let(:state_machine)   { assigned_case.state_machine }
      let(:assignment)      { assigned_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }

      before do
        allow(state_machine).to receive(:accept_responder_assignment)
        allow(state_machine).to receive(:accept_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.responder_assignment_accepted(responder, responding_team)
        expect(state_machine).to have_received(:accept_responder_assignment!).
                                   with(responder, responding_team)
        expect(state_machine).
          not_to have_received(:accept_responder_assignment)
      end
    end

    describe '#add_responses' do
      let(:accepted_case)   { create(:accepted_case)                          }
      let(:state_machine)   { accepted_case.state_machine                     }
      let(:assignment)      { accepted_case.responder_assignment }
      let(:responding_team) { assignment.team }
      let(:responder)       { assignment.team.responders.first }
      let(:responses)     do
        [
          build(
            :case_response,
            key: "#{SecureRandom.hex(16)}/responses/new response.pdf"
          )
        ]
      end


      context 'with mocked state machine calls' do
        before do
          allow(state_machine).to receive(:add_responses)
          allow(state_machine).to receive(:add_responses!)
        end

        it 'triggers the raising version of the event' do
          accepted_case.add_responses(responder, responses)
          expect(state_machine).to have_received(:add_responses!).
                                     with(responder,
                                          responding_team,
                                          ['new response.pdf'])
          expect(state_machine).
            not_to have_received(:add_responses)
        end

        it 'adds responses to case#attachments' do
          accepted_case.add_responses(responder.id, responses)
          expect(accepted_case.attachments).to match_array(responses)
        end
      end

      context 'with real state machine calls' do
        it 'changes the state from drafting to awaiting_dispatch' do
          expect(accepted_case.current_state).to eq 'drafting'
          accepted_case.add_responses(responder, responses)
          expect(accepted_case.current_state).to eq 'awaiting_dispatch'
        end
      end
    end

    describe '#respond' do
      let(:case_with_response) { create(:case_with_response)      }
      let(:state_machine)      { case_with_response.state_machine }

      before do
        allow(state_machine).to receive(:respond!)
        allow(state_machine).to receive(:respond)
      end

      it 'triggers the raising version of the event' do
        case_with_response.respond(case_with_response.responder)
        expect(state_machine).to have_received(:respond!)
                                   .with(case_with_response.responder,
                                         case_with_response.responding_team)
        expect(state_machine).not_to have_received(:respond)
      end
    end

    describe '#close' do
      let(:responded_case)  { create(:responded_case)      }
      let(:state_machine)   { responded_case.state_machine }

      before do
        allow(state_machine).to receive(:close!)
        allow(state_machine).to receive(:close)
      end

      it 'triggers the raising version of the event' do
        manager = responded_case.managing_team.managers.first
        responded_case.close(manager)
        expect(state_machine).to have_received(:close!)
                                   .with(manager, responded_case.managing_team)
        expect(state_machine).not_to have_received(:close)
      end
    end

    describe '#within_external_deadline?' do
      let(:foi) { create :category, :foi }
      let(:responded_case) do
        create :responded_case,
               category: foi,
               received_date: days_taken.business_days.ago,
               date_responded: Time.first_business_day(Date.today)
      end

      context 'the date responded is before the external deadline' do
        let(:days_taken) { foi.external_time_limit - 1 }

        it 'returns true' do
          expect(responded_case.within_external_deadline?).to eq true
        end
      end

      context 'the date responded is before on external deadline' do
        let(:days_taken) { foi.external_time_limit - 1 }

        it 'returns true' do
          expect(responded_case.within_external_deadline?).to eq true
        end
      end

      context 'the date responded is after the external deadline' do
        let(:days_taken) { foi.external_time_limit + 1 }

        it 'returns false' do
          expect(responded_case.within_external_deadline?).to eq false
        end
      end
    end
  end
end

