require 'rails_helper'

describe DeadlineFilter do

  before(:all) do
    @kase_1 = create :case, received_date: Date.today
    @kase_2 = create :case, received_date: Date.today
    @kase_3 = create :case, received_date: Date.today
  end

  after(:all) { DbHousekeeping.clean }

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { DeadlineFilter.new(arel, params) }

    context 'no cases with deadline in date range' do
      let(:params) { { external_deadline_from_dd: 4,
                        external_deadline_from_mm: 12,
                        external_deadline_from_yy: 2017,
                        external_deadline_to_dd: 25,
                        external_deadline_to_mm: 12,
                        external_deadline_to_yy: 2017,
                      } }
      it 'returns an empty collection' do
        expect(filter.call).to eq []
      end
    end

    context 'case with deadline within date rang' do
      let(:params) { { external_deadline_from_dd: 1,
                        external_deadline_from_mm: 4,
                        external_deadline_from_yy: 2018,
                        external_deadline_to_dd: 20,
                        external_deadline_to_mm: 4,
                        external_deadline_to_yy: 2018,
                      } }

      it 'returns only cases within date range' do
        expect(filter.call).to match_array [@kase_1, @kase_2]
      end
    end
  end
end
