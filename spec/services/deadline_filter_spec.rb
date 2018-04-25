require 'rails_helper'

describe DeadlineFilter do

  before(:all) do
    @kase_1 = create :case, final_deadline: Date.new(2018, 3, 11)
    @kase_2 = create :case, final_deadline: Date.new(2018, 3, 16)
    @kase_3 = create :case, final_deadline: Date.new(2018, 4, 21)
  end

  after(:all) { DbHousekeeping.clean }

  describe '#call' do
    let(:arel)    { Case::Base.all }
    let(:filter)  { DeadlineFilter.new(arel, params) }

    context 'no cases with deadline in date range' do
      from_date = Date.new(2017, 12, 4)
      to_date = Date.new(2017, 12, 25)
      let(:params) { { from: from_date, to: to_date } }
      it 'returns an empty collection' do
        expect(filter.call).to be_empty
      end
    end

    context 'case with deadline within date rang' do
      from_date = Date.new(2018, 3, 4)
      to_date = Date.new(2017, 4, 20)
      let(:params) { { from: from_date, to: to_date } }

      it 'returns only cases within date range' do
        expect(filter.call).to match_array [@kase_1, @kase_2]
      end
    end
  end
end
