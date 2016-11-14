require 'rails_helper'

describe DeadlineCalculator do

  subject { described_class }

  let(:foi_request) do
    build(:correspondence,
      received_date: Date.parse('05/08/2016'))
  end

  let(:general_enquiry) do
    build(:correspondence,
      received_date: Date.parse('05/08/2016'),
      category: create(:category, :gq))
  end

  describe '#internal_deadline' do
    describe 'freedom of information requests' do
      it 'is 10 working days from day 1' do
        Timecop.freeze(Date.parse('04/08/2016')) do
          expect(subject.internal_deadline(foi_request).
            strftime("%d/%m/%y")).
            to eq '19/08/16'
        end
      end
    end

    describe 'general enquiries' do
      it 'is 10 working days from day 1' do
        Timecop.freeze(Date.parse('04/08/2016')) do
          expect(subject.internal_deadline(general_enquiry).
            strftime("%d/%m/%y")).
            to eq '19/08/16'
        end
      end
    end
  end

  describe '#external_deadline' do
    describe 'freedom of information requests' do
      it 'is 20 working days from day 1' do
        Timecop.freeze(Date.parse('04/08/2016')) do
          expect(subject.external_deadline(foi_request).
            strftime("%d/%m/%y")).
            to eq '05/09/16'
        end
      end
    end

    describe 'general enquiries' do
      it 'is 15 working days from day 1' do
        Timecop.freeze(Date.parse('04/08/2016')) do
          expect(subject.external_deadline(general_enquiry).
            strftime("%d/%m/%y")).
            to eq '26/08/16'
        end
      end
    end
  end

  describe '#start_date' do
    describe 'is the first working day after the received date' do
      describe 'this is the following Monday when' do
        it 'received date is a Saturday' do
          expect(subject.start_date(Date.parse('13/08/2016')).
            strftime("%d/%m/%y")).
            to eq '15/08/16'
        end

        it 'received date is a Sunday' do
          expect(subject.start_date(Date.parse('14/08/2016')).
            strftime("%d/%m/%y")).
            to eq '15/08/16'
        end
      end

      describe 'this is the following day when' do
        it 'received date a Bank Holiday Monday' do
          expect(subject.start_date(Date.parse('29/08/2016')).
            strftime("%d/%m/%y")).
            to eq '30/08/16'
        end

        it 'received date is a normal Monday' do
          expect(subject.start_date(Date.parse('15/08/2016')).
            strftime("%d/%m/%y")).
            to eq '16/08/16'
        end
      end
    end
  end
end
