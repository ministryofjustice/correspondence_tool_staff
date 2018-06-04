require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
require File.join(Rails.root, 'spec', 'site_prism', 'support', 'helper_methods')


feature 'filters whittle down search results' do
  include Features::Interactions
  include PageObjects::Pages::Support

  before(:all) do
    @all_cases = {
      std_draft_foi:      { received_date: 6.business_days.ago },
      std_draft_foi_late: { received_date: 25.business_days.ago },
      std_closed_foi:     { received_date: 18.business_days.ago },
      trig_responded_foi: { received_date: 7.business_days.ago },
      trig_closed_foi:    { received_date: 15.business_days.ago },
      std_unassigned_irc: { received_date: 1.business_days.ago },
      std_unassigned_irt: { received_date: 2.business_days.ago },
      std_closed_irc:     { received_date: 17.business_days.ago },
      std_closed_irt:     { received_date: 16.business_days.ago },
    }
    @setup = StandardSetup.new(only_cases: @all_cases)
  end

  after(:all) do
    DbHousekeeping.clean
  end

  context 'type filter' do
    scenario 'filter by internal review for compliance, timeliness', js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers).to eq expected_case_numbers(
                                                   :std_draft_foi_late,
                                                   :trig_responded_foi,
                                                   :std_draft_foi,
                                                   :std_unassigned_irt,
                                                   :std_unassigned_irc,
                                                 )
      open_cases_page.filter_on('type', 'foi_standard', 'foi_trigger')

      expect(open_cases_page.case_numbers).to eq [@setup.trig_responded_foi.number]
      expect(open_cases_page.search_results_count.text).to eq '1 case found'
      open_cases_page.open_filter(:type)
      expect(open_cases_page.type_filter_panel.foi_standard_checkbox)
        .to be_checked
      expect(open_cases_page.type_filter_panel.foi_trigger_checkbox)
        .to be_checked

      # Now uncheck non-trigger and check trigger
      open_cases_page.remove_filter_on('type', 'foi_trigger')
      open_cases_page.filter_on('type', 'foi_non_trigger')

      expect(open_cases_page.case_numbers).to eq [
                                                @setup.std_draft_foi_late.number,
                                                @setup.std_draft_foi.number,
                                              ]
      open_cases_page.open_filter(:type)
      expect(open_cases_page.type_filter_panel.foi_non_trigger_checkbox)
        .to be_checked
      expect(open_cases_page.type_filter_panel.foi_trigger_checkbox)
        .not_to be_checked

      # Remove type filter using the crumb
      open_cases_page.filter_crumb_for('FOI - Standard').click

      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers :std_draft_foi,
                                              :std_draft_foi_late,
                                              :std_unassigned_irc,
                                              :std_unassigned_irt

      open_cases_page.open_filter(:type)
      expect(open_cases_page.type_filter_panel.foi_non_trigger_checkbox)
        .to be_checked
    end
  end

  context 'open case status filter' do
    scenario 'filter by unassigned status', js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers).to match_array expected_case_numbers(
                                                            :std_draft_foi,
                                                            :std_draft_foi_late,
                                                            :trig_responded_foi,
                                                            :std_unassigned_irc,
                                                            :std_unassigned_irt,
                                                          )
      open_cases_page.filter_on('status', 'unassigned')
      expect(open_cases_page.case_numbers).to match_array expected_case_numbers(:std_unassigned_irc, :std_unassigned_irt)
      open_cases_page.open_filter(:status)
      expect(open_cases_page.status_filter_panel.unassigned_checkbox)
        .to be_checked

      open_cases_page.filter_crumb_for('Needs reassigning').click

      expect(open_cases_page.case_numbers)
        .to match_array expected_case_numbers :std_draft_foi,
                                              :std_draft_foi_late,
                                              :trig_responded_foi,
                                              :std_unassigned_irc,
                                              :std_unassigned_irt
      expect(open_cases_page.search_results_count.text).to eq '5 cases found'

      open_cases_page.open_filter(:status)
      expect(open_cases_page.status_filter_panel.unassigned_checkbox)
        .not_to be_checked
    end
  end

  context 'all filters set' do
    before do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed

      open_cases_page.filter_on('type', 'foi_standard', 'foi_trigger')
      open_cases_page.filter_on(:timeliness, 'in_time')
      open_cases_page.filter_on('status', 'responded')
      open_cases_page.filter_on_deadline(from: Date.today,
                                         to: 15.business_days.from_now)
      @deadline_filter_text = "%s - %s" % [
        Date.today.strftime('%-d %b %Y'),
        15.business_days.from_now.strftime('%-d %b %Y')
      ]
    end

    # def date_range_text(start_date = Date.today, end_date = Date.today)
    #   "#{start_date.strftime('%d %b %Y')} - #{end_date.strftime('%d %b %Y')}"
    # end

    scenario 'clearing individual filters', js: true do
      expect(SearchQuery.count).to eq 5

      open_cases_page.filter_crumb_for(@deadline_filter_text).click

      expect(SearchQuery.count).to eq 5
      expect(open_cases_page.search_results_count.text).to eq '1 case found'
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).to be_present
      expect(open_cases_page.filter_crumb_for('In time'            )).to be_present
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for('Ready to close').click

      expect(SearchQuery.count).to eq 5
      expect(open_cases_page.search_results_count.text).to eq '1 case found'
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).to be_present
      expect(open_cases_page.filter_crumb_for('In time'            )).to be_present
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for('In time').click

      expect(SearchQuery.count).to eq 5
      expect(open_cases_page.search_results_count.text).to eq '1 case found'
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).to be_present
      expect(open_cases_page.filter_crumb_for('In time'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for('Trigger').click

      expect(SearchQuery.count).to eq 6
      expect(open_cases_page.search_results_count.text).to eq '3 cases found'
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for('In time'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present

      open_cases_page.filter_crumb_for('FOI - Standard').click

      expect(SearchQuery.count).to eq 7
      expect(open_cases_page.search_results_count.text).to eq '5 cases found'
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for('In time'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present
    end

    scenario 'clearing all filters', js: true do
      expect(open_cases_page.filter_crumb_for('Ready to close'     )).to be_present
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).to be_present

      open_cases_page.click_on 'Clear all filters'

      expect(open_cases_page.filter_crumb_for('Ready to close'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for('FOI - Standard'     )).not_to be_present
      expect(open_cases_page.filter_crumb_for('Trigger'            )).not_to be_present
      expect(open_cases_page.filter_crumb_for(@deadline_filter_text)).not_to be_present
    end
  end
end
