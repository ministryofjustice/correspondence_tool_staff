require 'rails_helper'

describe DeadlineCalculator do

  subject                 { described_class }
  let(:foi_request)       { build(:correspondence) }
  let(:general_enquiry)   { build(:correspondence, category: create(:category, :gq)) }

  context '#internal_deadline' do

    context 'freedom of information requests' do
      it 'is 10 working days from day 1' do
        Timecop.freeze(Date.parse('05/08/2016')) { expect(subject.internal_deadline(foi_request).strftime("%d/%m/%y")).to eq '19/08/16' }
      end
    end

    context 'general enquiries' do
      it 'is 10 working days from day 1' do
        Timecop.freeze(Date.parse('05/08/2016')) { expect(subject.internal_deadline(general_enquiry).strftime("%d/%m/%y")).to eq '19/08/16' }
      end
    end
  end

  context '#external_deadline' do

    context 'freedom of information requests' do
      it 'is 20 working days from day 1' do
        Timecop.freeze(Date.parse('05/08/2016')) { expect(subject.external_deadline(foi_request).strftime("%d/%m/%y")).to eq '05/09/16' }
      end
    end

    context 'general enquiries' do
      it 'is 15 working days from day 1' do
        Timecop.freeze(Date.parse('05/08/2016')) { expect(subject.external_deadline(general_enquiry).strftime("%d/%m/%y")).to eq '26/08/16' }
      end
    end
  end

  context '#start_date' do
    context 'is the first working day after the day of receipt (i.e. creation)' do

      it 'is the following Monday if day of receipt is a Saturday or Sunday' do
        Timecop.freeze(Date.parse('13/08/2016')) { expect(subject.start_date.strftime("%d/%m/%y")).to eq '15/08/16' }
        Timecop.freeze(Date.parse('14/08/2016')) { expect(subject.start_date.strftime("%d/%m/%y")).to eq '15/08/16' }
      end

      it 'is the following day if day of receipt is a Bank Holiday' do
        Timecop.freeze(Date.parse('29/08/2016')) { expect(subject.start_date.strftime("%d/%m/%y")).to eq '30/08/16' }
      end

      it 'is the next day if day of receipt is a normal Monday' do
        Timecop.freeze(Date.parse('15/08/2016')) { expect(subject.start_date.strftime("%d/%m/%y")).to eq '16/08/16' }
      end
    end
  end
end
