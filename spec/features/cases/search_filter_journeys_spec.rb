require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")
require Rails.root.join("spec/site_prism/support/helper_methods")

# rubocop:disable RSpec/BeforeAfterAll
feature "filters whittle down search results" do
  include Features::Interactions
  include PageObjects::Pages::Support

  before(:all) do
    CaseClosure::MetadataSeeder.seed!(verbose: false)

    @all_cases = %i[
      std_draft_foi
      std_closed_foi
      trig_responded_foi
      trig_closed_foi
      std_unassigned_irc
      std_unassigned_irt
      std_closed_irc
      std_closed_irt
      sar_noff_draft
    ]

    @setup = StandardSetup.new(only_cases: @all_cases)

    # add a common search term to them all
    #
    @setup.cases.each do |_kase_name, kase|
      kase.subject += " prison guards"
      kase.save!
    end
    Case::Base.update_all_indexes
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  describe "status filter" do
    scenario "filter by status: open", js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)
      cases_search_page.filter_on("status", "open")
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(
        :std_draft_foi,
        :trig_responded_foi,
        :std_unassigned_irc,
        :std_unassigned_irt,
        :sar_noff_draft,
      )

      cases_search_page.open_filter(:status)
      expect(cases_search_page.filter_status_content.open_checkbox)
        .to be_checked

      cases_search_page.filter_crumb_for("Open").click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:status)
      expect(cases_search_page.filter_status_content.open_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for("Open"))
        .not_to be_present
    end
  end

  describe "type filter" do
    scenario "filter by internal review for compliance, timeliness", js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          types: %w[foi_ir_compliance foi_ir_timeliness],
                          expected_cases: [
                            @setup.std_unassigned_irc,
                            @setup.std_unassigned_irt,
                            @setup.std_closed_irc,
                            @setup.std_closed_irt,
                          ])

      crumb_text = "FOI - Internal review for compliance + 1 more"
      cases_search_page.filter_crumb_for(crumb_text).click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.filter_type_content.foi_ir_compliance_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_type_content.foi_ir_timeliness_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for(crumb_text))
        .not_to be_present
    end

    scenario "filter by standard FOI and trigger", js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          types: %w[foi_standard],
                          sensitivity: %w[trigger],
                          expected_cases: [
                            @setup.trig_responded_foi,
                            @setup.trig_closed_foi,
                          ])

      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      cases_search_page.filter_crumb_for("Trigger").click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(:trig_responded_foi,
                                              :trig_closed_foi,
                                              :std_draft_foi,
                                              :std_closed_foi)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.filter_type_content.foi_standard_checkbox)
        .to be_checked
      expect(cases_search_page.filter_crumb_for("Trigger"))
        .not_to be_present

      cases_search_page.filter_crumb_for("FOI - Standard").click

      expect(cases_search_page.case_numbers)
        .to match_array expected_case_numbers(*@all_cases)
      cases_search_page.open_filter(:type)
      expect(cases_search_page.filter_type_content.foi_standard_checkbox)
        .not_to be_checked
      expect(cases_search_page.filter_crumb_for("FOI - Standard"))
        .not_to be_present
    end

    scenario "selecting both sensitivies then going back and unchecking one of them", js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)
      filter_on_type_step(page: cases_search_page,
                          sensitivity: %w[non_trigger trigger],
                          expected_cases: [
                            @setup.std_draft_foi,
                            @setup.std_closed_foi,
                            @setup.trig_responded_foi,
                            @setup.trig_closed_foi,
                            @setup.std_unassigned_irc,
                            @setup.std_unassigned_irt,
                            @setup.std_closed_irc,
                            @setup.std_closed_irt,
                            @setup.sar_noff_draft,
                          ])

      expect(cases_search_page.filter_crumb_for("Non-trigger + 1 more"))
        .to be_present

      # Now uncheck non-trigger
      cases_search_page.remove_filter_on("sensitivity", "non_trigger")
      expect(cases_search_page.case_numbers).to match_array expected_case_numbers(
        :trig_responded_foi,
        :trig_closed_foi,
      )
    end

    scenario "filter by non-offender SAR", js: true do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)

      filter_on_type_step(page: cases_search_page,
                          types: %w[sar_non_offender],
                          expected_cases: [@setup.sar_noff_draft])
    end

    scenario "user without sar permissions is filtering", js: true do
      foi             = find_or_create(:foi_correspondence_type)
      responding_team = create(:business_unit, correspondence_types: [foi])
      user            = create(:user, responding_teams: [responding_team])

      login_step(user:)
      cases_search_page.open_filter("type")
      expect(cases_search_page.filter_type_content).to have_no_sar_non_offender_checkbox
    end
  end

  describe "exemptions filter", js: true do
    before do
      @ex1 = create_case_with_exemptions(%w[s21 s22 s23])
      @ex2 = create_case_with_exemptions(%w[s27 s22 s40])
      @ex4 = create_case_with_exemptions(%w[s40])
      Case::Base.update_all_indexes
    end

    context "when specifying one exemption" do
      scenario "selects all cases closed with that exemption", js: true do
        login_step user: @setup.disclosure_bmt_user
        search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 12)
        cases_search_page.filter_on_exemptions(common: %w[s40])
        expect(cases_search_page.case_numbers).to match_array [@ex2.number, @ex4.number]

        cases_search_page.open_filter(:exemption)

        filter_exemption_content = cases_search_page.filter_exemption_content
        expect(filter_exemption_content.most_used.checkbox_for(:s40))
          .to be_checked
        expect(filter_exemption_content.exemption_all.checkbox_for(:s40))
          .to be_checked

        cases_search_page.filter_crumb_for("(s40) - Personal information").click
        cases_search_page.open_filter(:exemption)

        filter_exemption_content = cases_search_page.filter_exemption_content
        expect(filter_exemption_content.most_used.checkbox_for(:s40))
          .not_to be_checked
        expect(filter_exemption_content.exemption_all.checkbox_for(:s40))
          .not_to be_checked
      end
    end

    context "when specifying multiple exemptions", js: true do
      scenario "selects only cases that match ALL specified exemption" do
        login_step user: @setup.disclosure_bmt_user
        search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 12)
        cases_search_page.filter_on_exemptions(common: %w[s21 s22])
        expect(cases_search_page.case_numbers).to match_array [@ex1.number]

        cases_search_page.open_filter(:exemption)

        filter_exemption_content = cases_search_page.filter_exemption_content
        expect(filter_exemption_content.most_used.checkbox_for(:s21))
          .to be_checked
        expect(filter_exemption_content.most_used.checkbox_for(:s22))
          .to be_checked
        expect(filter_exemption_content.exemption_all.checkbox_for(:s21))
          .to be_checked
        expect(filter_exemption_content.exemption_all.checkbox_for(:s22))
          .to be_checked

        s21_plus_one = "(s21) - Information accessible by other means + 1 more"
        expect(cases_search_page.filter_crumb_for(s21_plus_one)).to be_present
      end
    end
  end

  context "when all filters set" do
    before do
      login_step user: @setup.disclosure_bmt_user
      search_for(page: open_cases_page, search_phrase: "prison guards", num_expected_results: 9)

      cases_search_page.filter_on("status", "open")
      cases_search_page.filter_on("type", "foi_standard")
      cases_search_page.filter_on("sensitivity", "trigger")
      cases_search_page.filter_on_exemptions(common: %w[s40])

      cases_search_page.filter_on_deadline("Today")

      @s40_exemption = "(s40) - Personal information"
      @from_to_date = "Deadline #{I18n.l Time.zone.today} - #{I18n.l Time.zone.today}"
    end

    scenario "clearing individual filters", js: true do
      expect(SearchQuery.count).to eq 7

      cases_search_page.filter_crumb_for(@from_to_date).click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for("Open")).to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present

      cases_search_page.filter_crumb_for(@s40_exemption).click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for("Open")).to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present

      cases_search_page.filter_crumb_for("Trigger").click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for("Open")).to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present

      cases_search_page.filter_crumb_for("FOI - Standard").click

      expect(SearchQuery.count).to eq 7
      expect(cases_search_page.filter_crumb_for("Open")).to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).not_to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present

      cases_search_page.filter_on("type", "foi_standard")
      cases_search_page.filter_on("sensitivity", "trigger")
      cases_search_page.filter_crumb_for("Open").click

      expect(SearchQuery.count).to eq 8
      expect(cases_search_page.filter_crumb_for("Open")).not_to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present
    end

    scenario "clearing all filters", js: true do
      expect(cases_search_page.filter_crumb_for("Open")).to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).to be_present

      cases_search_page.click_on "Clear all filters"

      expect(cases_search_page.filter_crumb_for("Open")).not_to be_present
      expect(cases_search_page.filter_crumb_for("FOI - Standard")).not_to be_present
      expect(cases_search_page.filter_crumb_for("Trigger")).not_to be_present
      expect(cases_search_page.filter_crumb_for(@s40_exemption)).not_to be_present
      expect(cases_search_page.filter_crumb_for(@from_to_date)).not_to be_present
    end
  end

  def expected_case_numbers(*case_names)
    case_names.map { |name| @setup.__send__(name) }.map(&:number)
  end

  def create_case_with_exemptions(exemption_codes)
    exemptions = exemption_codes.map { |code|
      CaseClosure::Exemption.__send__(code)
    }.compact
    raise "Not all codes can be found #{exemption_codes.inspect}" if exemptions.size != exemption_codes.size

    create :closed_case,
           subject: "Prison guards #{exemption_codes.join(',')}",
           info_held_status: find_or_create(:info_status, :held),
           outcome: find_or_create(:outcome, :refused),
           exemptions:
  end
end
# rubocop:enable RSpec/BeforeAfterAll
