# == Schema Information
#
# Table name: cases
#
#  id             :integer          not null, primary key
#  name           :string
#  email          :string
#  message        :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  category_id    :integer
#  received_date  :date
#  postal_address :string
#  subject        :string
#  properties     :jsonb
#  number         :string           not null
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

  let(:no_postal)           { build :case, postal_address: nil             }
  let(:no_postal_or_email)  { build :case, postal_address: nil, email: nil }
  let(:no_email)            { build :case, email: nil                      }
  let(:drafter)             { create :user, roles: ['drafter']             }
  let(:assigner)            { create :user, roles: ['assigner']            }

  describe 'has a factory' do
    it 'that produces a valid object by default' do
      expect(non_trigger_foi).to be_valid
    end
  end

  describe 'mandatory attributes' do
    it { should validate_presence_of(:name)          }
    it { should validate_presence_of(:message)       }
    it { should validate_presence_of(:received_date) }
    it { should validate_presence_of(:subject)       }
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

  describe '#drafter' do
    it 'is the currently assigned drafter' do
      allow(non_trigger_foi).to receive(:assignees).and_return [drafter]
      expect(non_trigger_foi.drafter).to eq drafter
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
        assignment = kase.assignments.detect(&:drafter?)
        expect do
          kase.assignments.delete(assignment)
        end.to change { Assignment.count }.by(-1)
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

  end

  describe 'state machine' do
    let(:kase) { create :case }

    describe '#state_machine' do
      subject { kase.state_machine }

      it { should be_an_instance_of(CaseStateMachine) }
      it { should have_attributes(object: kase)}
    end

    describe '#create_assignment' do
      let(:unassigned_case) { create :case }
      let(:assigned_case) { create :assigned_case }

      before do
        allow(unassigned_case.state_machine).to receive(:assign_responder)
      end

      it "creates no transition if the assignment isn't valid" do
        unassigned_case.create_assignment(
          assigner_id: assigner.id,
          assignee_id: drafter.id,
        )
        expect(unassigned_case.state_machine).not_to(
          have_received(:assign_responder).with(assigner.id, drafter.id)
        )
      end

      it 'returns the created assignment' do
        assignment = unassigned_case.create_assignment(
          assigner_id: assigner.id,
          assignee_id: drafter.id,
          assignment_type: 'drafter'
        )
        expect(assignment).to eq Assignment.last
      end

      context 'responder assignment' do
        it 'creates an assign_responder transition' do
          unassigned_case.create_assignment(
            assigner_id: assigner.id,
            assignee_id: drafter.id,
            assignment_type: 'drafter'
          )
          expect(unassigned_case.state_machine).to(
            have_received(:assign_responder).with(assigner.id, drafter.id)
          )
        end

        it 'creates a responder assignment' do
          expect(unassigned_case.assignments.detect(&:drafter?)).to be_nil
          unassigned_case.create_assignment(
            assigner_id: assigner.id,
            assignee_id: drafter.id,
            assignment_type: 'drafter'
          )
          expect(unassigned_case.assignments.detect(&:drafter?)).not_to be_nil
        end
      end
    end

    describe '#responder_assignment_rejected' do
      let(:assigned_case) { create :assigned_case }
      let(:state_machine) { assigned_case.state_machine }
      let(:assignment)    { assigned_case.assignments.detect(&:drafter?) }
      let(:drafter)       { assignment.assignee }
      let(:message)       { |example| "test #{example.description}" }

      before do
        allow(state_machine).to receive(:reject_responder_assignment)
        allow(state_machine).to receive(:reject_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.responder_assignment_rejected(drafter.id, message)
        expect(state_machine).to have_received(:reject_responder_assignment!).
                                   with(drafter.id, message)
        expect(state_machine).
          not_to have_received(:reject_responder_assignment)
      end
    end

    describe '#responder_assignment_accepted' do
      let(:assigned_case) { create :assigned_case }
      let(:state_machine) { assigned_case.state_machine }
      let(:assignment)    { assigned_case.assignments.detect(&:drafter?) }
      let(:drafter)       { assignment.assignee }

      before do
        allow(state_machine).to receive(:accept_responder_assignment)
        allow(state_machine).to receive(:accept_responder_assignment!)
      end

      it 'triggers the raising version of the event' do
        assigned_case.responder_assignment_accepted(drafter.id)
        expect(state_machine).to have_received(:accept_responder_assignment!).
                                   with(drafter.id)
        expect(state_machine).
          not_to have_received(:accept_responder_assignment)
      end
    end

  end
end
