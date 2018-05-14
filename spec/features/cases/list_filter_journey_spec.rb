require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
require File.join(Rails.root, 'spec', 'site_prism', 'support', 'helper_methods')


feature 'filters whittle down search results' do
  include Features::Interactions
  include PageObjects::Pages::Support

  before(:all) do
    @setup = StandardSetup.new(only_cases: [
        :std_draft_foi,
        :std_closed_foi,
        :trig_responded_foi,
        :trig_closed_foi,
        :std_unassigned_irc,
        :std_unassigned_irt,
        :std_closed_irc,
        :std_closed_irt
    ])
  end

  after(:all) do
    DbHousekeeping.clean
  end

  context 'type filter' do
    scenario 'filter by internal review for compliance, timeliness', js: true do
      login_step user: @setup.disclosure_bmt_user
      expect(open_cases_page).to be_displayed
      expect(open_cases_page.case_numbers).to match_array expected_case_numbers(:std_draft_foi,
                                                                                :trig_responded_foi,
                                                                                :std_unassigned_irc,
                                                                                :std_unassigned_irt)

      open_cases_page.filter_on('type', 'case_type_foi-standard', 'sensitivity_trigger')
      expect(open_cases_page.case_numbers).to eq [@setup.trig_responded_foi.number]

      # Now uncheck non-trigger and check trigger
      open_cases_page.remove_filter_on('type', 'sensitivity_trigger')
      open_cases_page.filter_on('type', 'sensitivity_non-trigger')

      expect(open_cases_page.case_numbers).to eq [@setup.std_draft_foi.number]
    end
  end
end
