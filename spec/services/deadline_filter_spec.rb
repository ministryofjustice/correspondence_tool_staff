require 'rails_helper'

describe DeadlineFilter do

  before(:all) do
    Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do
      @kase_1 = create :case, received_date: 30.business_days.ago
      @kase_2 = create :case, received_date: 25.business_days.ago
      @kase_3 = create :case, received_date: 100.business_days.ago
    end
  end

  after(:all) { DbHousekeeping.clean }

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { DeadlineFilter.new(arel, params) }

    context 'no cases with deadline in date range' do
      let(:params) { create_params(from_date:'4-12-2017',
                                   to_date:'25-12-2017') }

      it 'returns an empty collection' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to eq []
        end
      end
    end

    context 'case with deadline within date rang' do
      let(:params) { create_params(from_date:'1-4-2018',
                                   to_date:'20-4-2018') }

      it 'returns only cases within date range' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to match_array [@kase_1, @kase_2]
        end
      end
    end
  end

  private

  def create_params(from_date:, to_date:)
    from_date = from_date.split('-').map {|date| date.to_i }
    to_date = to_date.split('-').map {|date| date.to_i }
    { external_deadline_from_yy: from_date[2],
      external_deadline_from_mm: from_date[1],
      external_deadline_from_dd: from_date[0],
      external_deadline_to_yy: to_date[2],
      external_deadline_to_mm: to_date[1],
      external_deadline_to_dd: to_date[0]
    }
  end
end
