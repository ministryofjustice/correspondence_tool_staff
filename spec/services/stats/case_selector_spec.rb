require 'rails_helper'

module Stats
  describe CaseSelector do
    before(:all) do
      Timecop.freeze(Time.new(2018, 2, 25, 12, 22, 33)) do
        @period_start = Time.local(2017, 6, 1, 10, 45, 33)
        @period_end = Time.local(2017, 6, 15, 23, 59, 59)

        # cases are named ott_ctt where:
        # o = opened
        # tt = bs (before start date), os(on start date), dp(during period), oe(on end date), ap(after period)
        # c = closed
        # tt = bs (before start date), os(on start date), dp(during period), oe(on end date), ap(after period), xx(not closed)
        #
        # e.g.  obscos = opened before start date, closed on start date

        # opened before period start
        @obs_cbs = create :closed_case, name: '@obs_cbs', received_date: @period_start - 30.days, date_responded: @period_start - 2.days
        @obs_cos = create :closed_case, name: '@obs_cos', received_date: @period_start - 30.days, date_responded: @period_start
        @obs_cdp = create :closed_case, name: '@obs_cdp', received_date: @period_start - 10.days, date_responded: @period_end - 2.days
        @obs_coe = create :closed_case, name: '@obs_coe', received_date: @period_start - 10.days, date_responded: @period_end
        @obs_cap = create :closed_case, name: '@obs_cap', received_date: @period_start - 2.days, date_responded: @period_end + 2.days

        # opened on period start
        @oos_cdp = create :closed_case, name: '@oos_cdp', received_date: @period_start, date_responded: @period_end - 2.days
        @oos_coe = create :closed_case, name: '@oos_coe', received_date: @period_start, date_responded: @period_end
        @oos_cap = create :closed_case, name: '@oos_cap', received_date: @period_start, date_responded: @period_end + 2.days

        # opened during period
        @odp_cdp = create :closed_case, name: '@odp_cdp', received_date: @period_start + 2.days, date_responded: @period_end - 2.days
        @odp_coe = create :closed_case, name: '@odp_coe', received_date: @period_start + 2.days, date_responded: @period_end
        @odp_cap = create :closed_case, name: '@odp_cap', received_date: @period_start + 2.days, date_responded: @period_end + 2.days

        # opened on period end
        @ooe_cap = create :closed_case, name: '@ooe_cap', received_date: @period_end, date_responded: @period_end + 12.days

        # opened after period end
        @oap_cap = create :closed_case, name: '@oap_cap', received_date: @period_end + 2.days, date_responded: @period_end + 11.days

        # still open
        @obs_cxx = create :accepted_case, name: '@obs_cxx', received_date: @period_start - 2.days
        @oos_cxx = create :accepted_case, name: '@oos_cxx', received_date: @period_start
        @odp_cxx = create :accepted_case, name: '@odp_cxx', received_date: @period_start + 2.days
        @ooe_cxx = create :accepted_case, name: '@ooe_cxx', received_date: @period_end
        @oap_cxx = create :accepted_case, name: '@oap_cxx', received_date: @period_end + 2.days
      end
    end

    after(:all) { DbHousekeeping.clean }

    let(:selector)    { CaseSelector.new(Case::Base.all) }

    describe '.ids_for_cases_received_in_period' do
      it 'returns an array of all cases received in period' do
        expected_ids = [ @oos_cdp, @oos_coe, @oos_cap, @odp_cdp, @odp_coe, @odp_cap, @ooe_cap, @oos_cxx, @odp_cxx, @ooe_cxx ].map(&:id)
        expect(selector.ids_for_cases_received_in_period(@period_start, @period_end)).to match_array(expected_ids)
      end
    end

    describe '.ids_for_cases_open_during_period_still_not_closed' do
      it 'returns an array of ids of still open cases that were open during the period' do
        expected_ids = [ @obs_cxx, @oos_cxx, @odp_cxx, @ooe_cxx ].map(&:id)
        expect(selector.ids_for_cases_open_during_period_still_not_closed(@period_start, @period_end)).to match_array(expected_ids)
      end
    end

    describe '.ids_for_cases_open_at_start_of_period_and_since_closed' do
      it 'returns an array of case ids that were open at the end of the period but closed since' do
        expected_ids = [ @obs_cos, @obs_cdp, @obs_coe, @obs_cap ].map(&:id)
        expect(selector.ids_for_cases_open_at_start_of_period_and_since_closed(@period_start, @period_end)).to match_array expected_ids
      end
    end

    describe '.ids_for_period' do
      context 'using Class name' do
        it 'returns an array of case_ids that were received or open during period' do
          expected_ids = [ @obs_cos, @obs_cdp, @obs_coe, @obs_cap,
                           @oos_cdp, @oos_coe, @oos_cap,
                           @odp_cdp, @odp_coe, @odp_cap,
                           @ooe_cap,
                           @obs_cxx, @oos_cxx, @odp_cxx, @ooe_cxx ].map(&:id)
          expect(selector.ids_for_period(@period_start, @period_end)).to match_array expected_ids
        end
      end

      context 'using scope' do
        it 'returns an array of case_ids that were received or open during period' do
          expected_ids = [ @obs_cos, @obs_cdp, @obs_coe, @obs_cap,
                           @oos_cdp, @oos_coe, @oos_cap,
                           @odp_cdp, @odp_coe, @odp_cap,
                           @ooe_cap,
                           @obs_cxx, @oos_cxx, @odp_cxx, @ooe_cxx ].map(&:id)
          expect(CaseSelector.new(Case::Base.all).ids_for_period(@period_start, @period_end)).to match_array expected_ids
        end
      end
    end


  end
end
