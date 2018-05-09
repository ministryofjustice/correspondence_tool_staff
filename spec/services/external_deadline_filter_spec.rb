require 'rails_helper'

describe ExternalDeadlineFilter do

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
    let(:filter)  { ExternalDeadlineFilter.new(search_query, arel) }

    context 'no cases with deadline in date range' do
      let(:search_query) { create :search_query,
                            external_deadline_from: Date.new(2017, 12, 4),
                            external_deadline_to: Date.new(2017, 12, 25) }


      it 'returns an empty collection' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to eq []
        end
      end
    end

    context 'case with deadline within date rang' do

      let(:search_query) { create :search_query,
                            external_deadline_from: Date.new(2018, 4, 1),
                            external_deadline_to: Date.new(2018, 4, 25) }

      it 'returns only cases within date range' do
        Timecop.freeze(Time.new(2018, 4, 26,14, 57, 0)) do

          expect(filter.call).to match_array [@kase_1, @kase_2]
        end
      end
    end
  end
end
