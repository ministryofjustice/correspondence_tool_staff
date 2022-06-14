require 'spec_helper'
require_relative '../support/forms/form_validation_shared_examples'

RSpec.describe RetentionScheduleForm do
  it_behaves_like 'a date question form', attribute_name: :planned_destruction_date do
    before do
      allow(subject).to receive(:destruction_date_after_close_date).and_return(true)
    end
  end

  describe 'logic specific to this form' do
    let(:record) { double('Record', case: case_double) }
    let(:case_double) { double(Case::Base, date_responded: Date.today) }

    let(:planned_destruction_date) { Date.tomorrow }

    let(:arguments) { {
      record: record,
      planned_destruction_date: planned_destruction_date,
    } }

    subject { described_class.new(arguments) }

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

    describe '#save' do
      context 'when form is valid' do
        it 'saves the record' do
          expect(record).to receive(:update).with(
            planned_destruction_date: planned_destruction_date,
          ).and_return(true)

          expect(subject.save).to be(true)
        end
      end
    end
  end
end
