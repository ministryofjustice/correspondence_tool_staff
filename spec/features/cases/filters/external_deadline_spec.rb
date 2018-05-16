require "rails_helper"

feature 'filtering by external deadline' do
  include Features::Interactions

  describe 'external deadline filter', js: true do
    before(:all) do
      Timecop.freeze(Time.local(2018, 5, 11, 12, 0, 0))

      @all_cases = [
        :std_draft_foi,
        :std_closed_foi,
      ]

      @setup = StandardSetup.new(only_cases: @all_cases)

      @case_due_today = create :case,
                               received_date: 20.business_days.ago,
                               subject: 'prison guards today'
      @case_due_next_3_days = create :case,
                                     received_date: 18.business_days.ago,
                                     subject: 'prison guards next 3 days'
      @case_due_next_10_days = create :case,
                                      received_date: 10.business_days.ago,
                                      subject: 'prison guards next 10 days'

      @all_case_numbers = @setup.cases.values.map(&:number) +
                          [
                            @case_due_today.number,
                            @case_due_next_3_days.number,
                            @case_due_next_10_days.number,
                          ]

      @all_open_case_numbers = [ @setup.std_draft_foi.number,
                                 @case_due_today.number,
                                 @case_due_next_3_days.number,
                                 @case_due_next_10_days.number
                               ]


      # add a common search term to them all
      #
      @setup.cases.each do | _kase_name, kase |
        kase.subject += ' prison guards'
        kase.save!
      end
      Case::Base.update_all_indexes
    end

    after(:all) do
      DbHousekeeping.clean
      Timecop.return
    end

    context 'filtering on the open cases page' do
      before do
        login_step user: @setup.disclosure_bmt_user
      end

      scenario 'filtering for today' do
        filter_today_and_expect_correct_results(open_cases_page, @all_open_case_numbers)
      end

      scenario 'filtering for the next 3 days' do
        filter_next_three_days_and_expect_correct_results(open_cases_page, @all_open_case_numbers)
      end

      scenario 'filtering for the next 10 days' do
        filter_next_ten_days_and_expect_correct_results(open_cases_page, @all_open_case_numbers)
      end

      scenario 'filtering for custom from and to date' do
        filter_custom_dates_and_expect_correct_results(open_cases_page, @all_open_case_numbers)
      end
    end

    context 'filtering on the search page' do
      before do
        login_step user: @setup.disclosure_bmt_user
        search_for(search_phrase: 'prison guards', num_expected_results: 5)
      end

      scenario 'filtering for today' do
        filter_today_and_expect_correct_results(cases_search_page, @all_case_numbers)
      end

      scenario 'filtering for the next 3 days' do
        filter_next_three_days_and_expect_correct_results(cases_search_page, @all_case_numbers)
      end

      scenario 'filtering for the next 10 days' do
        filter_next_ten_days_and_expect_correct_results(cases_search_page, @all_case_numbers)
      end

      scenario 'filtering for custom from and to date' do
        filter_custom_dates_and_expect_correct_results(cases_search_page, @all_case_numbers)
      end
    end


    def filter_today_and_expect_correct_results(page, case_numbers)
      from_date = Date.today
      to_date   = Date.today

      expect(page.case_numbers).to match_array case_numbers

      page.filter_on_deadline('Today')

      expect(page.case_numbers).to match_array [
                                                                @case_due_today.number
                                                            ]

      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to eq from_date
      expect(page.deadline_filter_panel.to_date).to eq to_date

      from_to_date_text = "#{I18n.l from_date} - #{I18n.l to_date}"
      page.filter_crumb_for(from_to_date_text).click

      expect(page.case_numbers).to match_array case_numbers
      expect(page.filter_crumb_for(from_to_date_text)).not_to be_present
      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to be_nil
      expect(page.deadline_filter_panel.to_date).to be_nil
    end

    def filter_next_three_days_and_expect_correct_results(page, case_numbers)
      from_date = Date.today
      to_date   = 3.business_days.from_now.to_date

      page.filter_on_deadline('In the next 3 days')

      expect(page.case_numbers).to match_array [
                                                                @case_due_today.number,
                                                                @case_due_next_3_days.number
                                                            ]

      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to eq from_date
      expect(page.deadline_filter_panel.to_date).to eq to_date

      from_to_date_text = "#{I18n.l from_date} - #{I18n.l to_date}"
      page.filter_crumb_for(from_to_date_text).click

      expect(page.case_numbers).to match_array case_numbers
      expect(page.filter_crumb_for(from_to_date_text)).not_to be_present
      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to be_nil
      expect(page.deadline_filter_panel.to_date).to be_nil
    end
    
    def filter_next_ten_days_and_expect_correct_results(page, case_numbers)
      from_date = Date.today
      to_date   = 10.business_days.from_now.to_date

      page.filter_on_deadline('In the next 10 days')

      expect(page.case_numbers).to match_array [
                                                                @case_due_today.number,
                                                                @case_due_next_3_days.number,
                                                                @case_due_next_10_days.number,
                                                            ]

      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to eq from_date
      expect(page.deadline_filter_panel.to_date).to eq to_date

      from_to_date_text = "#{I18n.l from_date} - #{I18n.l to_date}"
      page.filter_crumb_for(from_to_date_text).click

      expect(page.case_numbers).to match_array case_numbers
      expect(page.filter_crumb_for(from_to_date_text)).not_to be_present
      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to be_nil
      expect(page.deadline_filter_panel.to_date).to be_nil
    end
    
    def filter_custom_dates_and_expect_correct_results(page, case_numbers)
      from_date = 5.business_days.from_now.to_date
      to_date   = 12.business_days.from_now.to_date

      page.filter_on_deadline(from: from_date, to: to_date)

      expect(page.case_numbers).to match_array [
                                                                @case_due_next_10_days.number,
                                                            ]

      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to eq from_date
      expect(page.deadline_filter_panel.to_date).to eq to_date

      from_to_date_text = "#{I18n.l from_date} - #{I18n.l to_date}"
      page.filter_crumb_for(from_to_date_text).click

      expect(page.case_numbers).to match_array case_numbers
      expect(page.filter_crumb_for(from_to_date_text)).not_to be_present
      page.open_filter(:deadline)
      expect(page.deadline_filter_panel.from_date).to be_nil
      expect(page.deadline_filter_panel.to_date).to be_nil
    end
  end
end
