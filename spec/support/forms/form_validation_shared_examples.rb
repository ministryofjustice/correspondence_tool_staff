RSpec.shared_examples 'a date question form' do |options|
  let(:question_attribute) { options[:attribute_name] }

  let(:arguments) { {
    record: record,
    "#{question_attribute}_yyyy" => date_value[0],
    "#{question_attribute}_mm"   => date_value[1],
    "#{question_attribute}_dd"   => date_value[2],
  } }

  let(:record) { double('Record') }
  let(:date_value) { %w(2018 12 31) }

  subject { described_class.new(arguments) }

  describe '#save' do
    context 'date validation' do
      context 'when date is not given' do
        let(:date_value) { [] }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.added?(question_attribute, :blank)).to eq(true)
        end
      end

      context 'when day part of the date is missing' do
        let(:date_value) { %w(2018 12 nil) }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.added?(question_attribute, 'Invalid date')).to eq(true)
        end
      end

      context 'when month part of the date is missing' do
        let(:date_value) { %w(2018 nil 31) }

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.added?(question_attribute, 'Invalid date')).to eq(true)
        end
      end

      context 'when date is invalid' do
        let(:date_value) { %w(2018 15 31) } # Month 15

        it 'returns false' do
          expect(subject.save).to be(false)
        end

        # ActsAsGovUkDate gem will not set an error symbol but instead an error message
        it 'has a validation error on the field' do
          expect(subject).to_not be_valid
          expect(subject.errors.added?(question_attribute, 'Invalid date')).to eq(true)
        end
      end
    end
  end
end
