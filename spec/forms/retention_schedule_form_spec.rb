require 'spec_helper'
require_relative '../support/forms/form_validation_shared_examples'

RSpec.describe RetentionScheduleForm do
  it_behaves_like 'a date question form', attribute_name: :planned_destruction_date do
    before do
      # We stub these as we will test more thoroughly in separate scenarios
      allow(subject).to receive(:destruction_date_after_close_date).and_return(true)
      allow(subject).to receive(:state_choices).and_return([])
    end
  end

  describe 'logic specific to this form' do
    let(:record) { double('Record', case: case_double, not_set?: schedule_not_set) }
    let(:case_double) { double(Case::Base, date_responded: Date.today) }

    let(:planned_destruction_date) { Date.tomorrow }
    let(:state) { RetentionSchedule::STATE_NOT_SET.to_s }
    let(:schedule_not_set) { true }

    let(:arguments) { {
      record: record,
      planned_destruction_date: planned_destruction_date,
      state: state,
    } }

    subject { described_class.new(arguments) }

    context '#state_choices' do
      context 'when the schedule has not been set yet' do
        it 'shows only the relevant values' do
          expect(subject.state_choices).to eq(%w(not_set retain review to_be_anonymised))
        end
      end

      context 'when the schedule has been set already' do
        let(:schedule_not_set) { false }

        it 'shows only the relevant values' do
          expect(subject.state_choices).to eq(%w(retain review to_be_anonymised))
        end
      end
    end

    context 'destruction_date_after_close_date validation' do
      context 'when the `planned_destruction_date` is before the `date_responded`' do
        let(:planned_destruction_date) { Date.yesterday }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.added?(:planned_destruction_date, :before_closure)).to eq(true)
        end
      end

      context 'when the `planned_destruction_date` is after the `date_responded`' do
        it 'has no validation errors on the field' do
          expect(subject).to be_valid
          expect(subject.errors.added?(:planned_destruction_date)).to eq(false)
        end
      end
    end

    context 'state validation' do
      context 'when `state` is not present' do
        let(:state) { nil }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.of_kind?(:state, :inclusion)).to eq(true)
        end
      end

      context 'when `state` is not a valid value' do
        let(:state) { 'foobar' }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.of_kind?(:state, :inclusion)).to eq(true)
        end
      end

      context 'when `state` is `not_set` but the schedule has been already set' do
        let(:schedule_not_set) { false }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.of_kind?(:state, :inclusion)).to eq(true)
        end
      end
    end

    describe '#save' do
      context 'when form is valid' do
        it 'saves the record' do
          expect(record).to receive(:update).with(
            planned_destruction_date: planned_destruction_date,
            state: state,
          ).and_return(true)

          expect(subject.save).to be(true)
        end
      end
    end
  end
end
