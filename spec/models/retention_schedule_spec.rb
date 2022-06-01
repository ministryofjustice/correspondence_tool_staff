require 'rails_helper'
require 'aasm/rspec'

RSpec.describe RetentionSchedule, type: :model do

  let(:kase) { create(:offender_sar_case) }
  let(:complaint_kase) { create(:offender_sar_complaint) }
  let(:foi_kase) { create(:foi_case) }

  let(:retention_schedule) { 
    RetentionSchedule.new(
      case: kase, 
      planned_destruction_date: Date.today
    ) 
  }

  let(:retention_schedule_for_complaint) { 
    RetentionSchedule.new(
      case: complaint_kase, 
      planned_destruction_date: Date.today
    ) 
  }

  let(:retention_schedule_foi) { 
    RetentionSchedule.new(
      case: foi_kase, 
      planned_destruction_date: Date.today
    ) 
  }


  describe 'deplay values for states' do
    it 'has correct display values for its states' do
      retention_schedule = RetentionSchedule.new(
        case: kase, 
        planned_destruction_date: Date.today
      ) 

      expect(retention_schedule.aasm.human_state).to match('Not set')

      retention_schedule.mark_for_retention
      expect(retention_schedule.aasm.human_state).to match('Retain')

      retention_schedule.mark_for_review
      expect(retention_schedule.aasm.human_state).to match('Review')

      retention_schedule.mark_for_anonymisation
      expect(retention_schedule.aasm.human_state).to match('Destroy')

      retention_schedule.anonymise!
      expect(retention_schedule.aasm.human_state).to match('Anonymised')
    end
  end

  describe 'state transitions' do
    it 'has an initial state of "not_set"' do
      expect(retention_schedule).to have_state(:not_set)
    end

    it 'allows the correct transitions' do
      expect(retention_schedule).to transition_from(:not_set, :review, :retain)
        .to(:retain).on_event(:mark_for_retention)

      expect(retention_schedule).to transition_from(:not_set, :retain, :to_be_anonymised)
        .to(:review).on_event(:mark_for_review)

      expect(retention_schedule).to transition_from(:not_set, :retain, :review)
        .to(:to_be_anonymised).on_event(:mark_for_anonymisation)

      expect(retention_schedule).to transition_from(:to_be_anonymised)
        .to(:anonymised).on_event(:anonymise!)

      expect(retention_schedule).to transition_from(:retain)
        .to(:not_set).on_event(:unlist)
    end

    it 'disallows incorrect transitions' do
      expect(retention_schedule).to_not transition_from(:not_set, :retain, :review)
        .to(:destroyed).on_event(:anonymise!)

      expect(retention_schedule).to_not transition_from(:review, :to_be_anonymised)
        .to(:unlist).on_event(:unlist)

      retention_schedule.mark_for_anonymisation
      retention_schedule.anonymise!

      expect(retention_schedule).to have_state(:anonymised)
      expect(retention_schedule).to_not allow_transition_to(
        :not_set, :retain, :review, :to_be_anonymised
      )
    end
  end

  describe 'validations' do
    it { should belong_to(:case).class_name('Case::SAR::Offender') }
    it { should validate_presence_of(:case) }
    it { should validate_presence_of(:planned_destruction_date) }
    
    it 'should be valid' do
      expect(retention_schedule).to be_valid
    end
  end

  describe 'associations' do
    it 'can return associated Offender SAR case' do
      expect(retention_schedule).to be_valid
      expect(retention_schedule.case).to be(kase)
    end

    it 'can return associated Offender SAR Complaint case' do
      expect(retention_schedule_for_complaint).to be_valid
      expect(retention_schedule_for_complaint.case).to be(complaint_kase)
    end

    # remove this test when retention_schedule roled out to all cases
    it 'cannot be associated with an non-offender SAR case' do
      expect { 
        retention_schedule_foi.save 
      }.to raise_error(ActiveRecord::AssociationTypeMismatch)
    end

    it 'kase can return associated case' do
      retention_schedule.save
      expect(kase.retention_schedule).to eq(retention_schedule)
    end
  end

  describe 'class methods' do
    describe '.common_date_viewable_from_range' do
      it 'returns a range that is correct' do
        class_range = RetentionSchedule.common_date_viewable_from_range
        expected_range = 4.months.ago..Date.today

        expect(class_range).to be_a(Range)
        expect(class_range.begin.day).to match(expected_range.begin.day)
        expect(class_range.end).to match(expected_range.end)
      end
    end

    describe '.states_map' do
      it 'returns a map of states and their corresponding display names' do
        expect(
          described_class.states_map
        ).to eq(
          { 
            not_set: 'Not set', 
            retain: 'Retain', 
            review: 'Review', 
            to_be_anonymised: 'Destroy', 
            anonymised: 'Anonymised' 
          }
        )
      end
    end
  end
end
