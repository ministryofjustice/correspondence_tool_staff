require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')



feature 'filters whittle down search results' do
  include Features::Interactions
  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)

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
  end

  context 'status filter' do
    scenario 'filter by status: open', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('status', 'status_open')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(:std_draft_foi,
                                                                                  :trig_responded_foi,
                                                                                  :std_unassigned_irc,
                                                                                  :std_unassigned_irt)
    end
  end


  context 'type filter' do
    scenario 'filter by internal review for compliance, timeliness', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'case_type_foi-ir-compliance', 'case_type_foi-ir-timeliness')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers( :std_unassigned_irc,
                                                                                   :std_unassigned_irt,
                                                                                   :std_closed_irc,
                                                                                   :std_closed_irt)
    end

    scenario 'filter by standard FOI and trigger', js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'case_type_foi-standard', 'sensitivity_trigger')
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers( :trig_responded_foi, :trig_closed_foi)
    end

    scenario 'selecting both sensitivies then going back and unchecking one of them' do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 8)
      cases_search_page.filter_on('type', 'sensitivity_non-trigger', 'sensitivity_trigger')

      expect(cases_search_page.case_numbers).to  match_array expected_case_numbers(  :std_draft_foi,
                                                                                    :std_closed_foi,
                                                                                    :trig_responded_foi,
                                                                                    :trig_closed_foi,
                                                                                    :std_unassigned_irc,
                                                                                    :std_unassigned_irt,
                                                                                    :std_closed_irc,
                                                                                    :std_closed_irt)

      # Now uncheck non-trigger
      cases_search_page.remove_filter_on('type', 'sensitivity_non-trigger')
      expect(cases_search_page.case_numbers).to  match_array expected_case_numbers( :trig_responded_foi,
                                                                                    :trig_closed_foi)


    end
  end


  context 'exemptions filter', js: true do
    before(:all) do
      @ex1 = create_case_with_exemptions(%w{ s21 s22 s23 })
      @ex2 = create_case_with_exemptions(%w{ s27 s22 s40 })
      @ex4 = create_case_with_exemptions(%w{ s40 })
      Case::Base.update_all_indexes
    end

    context 'specifying one exemtpion' do
      scenario 'selects all cases closed with that exemption', js: true do
        login_step user: @setup.disclosure_bmt_user
        search_for(search_phrase: 'prison guards', num_expected_results: 11)
        cases_search_page.filter_on_exemptions(common: %w{ s40 } )
        expect(cases_search_page.case_numbers).to match_array [ @ex2.number, @ex4.number ]
      end
    end

    context 'specifying multiple exemptions' do
      scenario 'selects only cases that match ALL specified exemption' do
        login_step user: @setup.disclosure_bmt_user
        search_for(search_phrase: 'prison guards', num_expected_results: 11)
        cases_search_page.filter_on_exemptions(common: %w{ s21 s22 } )
        expect(cases_search_page.case_numbers).to match_array [ @ex1.number  ]
      end
    end
  end


  context 'assigned business unit filter', js: true do
    it 'returns cases assigned to the specified business units' do
      login_step user: @setup.disclosure_bmt_user
      search_for(search_phrase: 'prison guards', num_expected_results: 11)
      cases_search_page.filter_tab_links.assigned_to_tab.click
      cases_search_page.filters.assigned_to_filter_panel.business_unit_search_term.set('main')
      cases_search_page.filters.assigned_to_filter_panel.main_responding_team_checkbox.click
      cases_search_page.filters.assigned_to_filter_panel.apply_filter_button.click

      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(:std_draft_foi,
                                                                                  :trig_responded_foi,
                                                                                  :trig_closed_foi)
    end

  end



  def expected_case_numbers(*case_names)
    case_names.map{ |name| @setup.__send__(name) }.map(&:number)
  end

  def create_case_with_exemptions(exemption_codes)
    exemptions = []
    exemption_codes.each do |code|
      exemptions << CaseClosure::Exemption.__send__(code)
    end
    create :closed_case,
           subject: "Prison guards #{exemption_codes.join(',')}",
           info_held_status: find_or_create(:info_status, :held),
           outcome: find_or_create(:outcome, :refused),
           exemptions: exemptions
  end
end

