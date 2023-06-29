###################################
#
# Stats - Downloading stats & custom reports
#
###################################

# Manager/responder signs in
# Views "Statistics" and displays stats page
# Clicks on R004 report
#   - expect report to download
# Clicks on R005 report
#   - expect report to download
# Clicks on "Create custom report" button
# "Create custom report page loads up"
# select a random report
# select a data range
# clicks export
# get flash click link to downloads
# downloads and redirects to custom page

require "rails_helper"
require Rails.root.join("db/seeders/case_closure_metadata_seeder")
require Rails.root.join("db/seeders/report_type_seeder")

# rubocop:disable RSpec/BeforeAfterAll
feature "Downloading stats(csv) from the system" do
  given(:manager)   { find_or_create :disclosure_bmt_user }
  given(:responder) { find_or_create :foi_responder }
  given(:kase)      { create :case }

  before(:all) do
    DbHousekeeping.clean
    CaseClosure::MetadataSeeder.seed!(verbose: false)
    all_reports = ReportType.all

    # Perform check for existence of ReportType to duplication errors
    %i[r002 r003 r004 r005 r007 r102 r103 r105 r205].each do |report_type|
      unless all_reports.any? { |rt| rt.abbr == report_type.to_s.upcase }
        create(:report_type, report_type)
      end
    end
  end

  after(:all) do
    DbHousekeeping.clean(seed: true)
  end

  background do
    manager
    responder
    kase
  end
  context "when a manager" do
    scenario "standard reports" do
      # Manager creates & assigns to kilo
      login_as_manager
      all_reports = ReportType.all
      expect(all_reports.count).to be >= 9

      abbrs = []
      all_reports.each do |report_item|
        abbrs << report_item.abbr
      end
      expect(abbrs.include?("R105")).to be true
      expect(abbrs.include?("R004")).to be true
      expect(abbrs.include?("R005")).to be true

      views_stats_home_page
      download_r105_report
      download_r004_report
      download_r005_report
    end

    scenario "custom reports" do
      # Manager creates & assigns to kilo
      login_as_manager
      views_stats_home_page
      view_custom_report_creation_page
      create_custom_r003_report
      create_custom_r004_report
      download_custom_r004_report
    end
  end

  scenario "closed cases report", js: true do
    login_as_manager
    views_stats_home_page
    view_custom_report_creation_page
    create_custom_r007_report
  end

  context "when a responder" do
    scenario "standard reports" do
      # Manager creates & assigns to kilo
      login_as_responder
      views_stats_home_page
      download_r004_report
      download_r005_report
    end

    scenario "custom reports" do
      # Manager creates & assigns to kilo
      login_as_responder
      views_stats_home_page
      view_custom_report_creation_page
      create_custom_r003_report
      create_custom_r004_report
      download_custom_r004_report
    end
  end

private

  def login_as_manager
    login_as manager

    open_cases_page.load
  end

  def login_as_responder
    login_as responder

    open_cases_page.load
  end

  def views_stats_home_page
    open_cases_page.primary_navigation.stats.click
    expect(stats_index_page).to be_displayed
  end

  def download_r004_report
    report = stats_index_page.reports.detect { |r| r.download_link.text =~ /Cabinet Office report/ }
    report.download_link.click
    expect(page.response_headers["Content-Disposition"])
        .to match(/filename="r004_cabinet_office_report.csv"/)
    stats_index_page.load
  end

  def download_r005_report
    report = stats_index_page.reports.detect { |r| r.download_link.text =~ /Monthly report/ }
    report.download_link.click
    expect(page.response_headers["Content-Disposition"])
        .to match(/filename="r005_monthly_performance_report.xlsx"/)
    stats_index_page.load
  end

  def download_r105_report
    stats_index_page.reports.last.download_link.click
    expect(page.response_headers["Content-Disposition"])
        .to match(/filename="r105_sar_monthly_performance_report.xlsx"/)
    stats_index_page.load
  end

  def download_r205_report
    stats_index_page.offender_sar.reports.last.download_link.click
    expect(page.response_headers["Content-Disposition"])
      .to match(/filename="r205_offender_sar_monthly_performance_report.xlsx"/)
    stats_index_page.load
  end

  def view_custom_report_creation_page
    stats_index_page.custom_reports.click
    expect(stats_new_page).to be_displayed
  end

  def create_custom_r003_report
    r003 = ReportType.where(abbr: "R003").first
    stats_new_page.fill_in_form("foi", r003.id, Time.zone.yesterday, Time.zone.today)
    stats_new_page.submit_button.click

    expect(stats_new_page.success_message).to have_download_link
  end

  def create_custom_r004_report
    r004 = ReportType.r004
    stats_new_page.fill_in_form("foi", r004.id, Time.zone.yesterday, Time.zone.today)
    stats_new_page.submit_button.click

    expect(stats_new_page.success_message).to have_download_link
  end

  def create_custom_r007_report
    stats_new_page.choose_type_of_correspondence("closed_cases")
    stats_new_page.fill_in_period_start(Time.zone.yesterday)
    stats_new_page.fill_in_period_end(Time.zone.yesterday)
    stats_new_page.submit_button.click

    # @note (Mohammed Seedat): cannot add expectations until new confirmation
    #   screen is completed
  end

  def download_custom_r004_report
    stats_new_page.success_message.download_link.click
    expect(page.response_headers["Content-Disposition"])
        .to match(/filename="r004_cabinet_office_report\.csv"/)

    stats_new_page.load
  end
end
# rubocop:enable RSpec/BeforeAfterAll
