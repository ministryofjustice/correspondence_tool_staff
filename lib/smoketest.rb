require "mechanize"

# SETTINGS__SMOKE_TESTS__USERNAME - Login username
# SETTINGS__SMOKE_TESTS__PASSWORD - Users password
# SETTINGS__SMOKE_TESTS__SITE_URL - Applications url

# rubocop:disable Rails/Exit
class Smoketest
  def initialize
    check_settings
    @username = Settings.smoke_tests.username
    @password = Settings.smoke_tests.password
    @site_url = Settings.smoke_tests.site_url
    @agent = Mechanize.new
    @case_number = nil
    @case_summary = nil
  end

  def run
    visit_service
    check_open_cases_list_page
    view_random_case
    check_case_details_page
    info "Smoketest has finished"
  end

private

  def check_settings
    @env_vars_ok = true

    if Settings.smoke_tests.username.nil?
      missing_env_var("SMOKE_TESTS__USERNAME")
    end

    if Settings.smoke_tests.password.nil?
      missing_env_var("SMOKE_TESTS__PASSWORD")
    end

    if Settings.smoke_tests.site_url.nil?
      missing_env_var("SMOKE_TESTS__SITE_URL")
    end

    unless @env_vars_ok
      puts "Fix enviroment variables before proceeding"
      exit 2
    end
  end

  def missing_env_var(var)
    info "!!! ERROR - Environment variable SETTINGS__#{var} not set!"
    @env_vars_ok = false
  end

  def visit_service
    info ".. Smoketest signs into the service"

    if ENV.key? "http_proxy"
      (proxy_host, proxy_port) = ENV["http_proxy"].split ":"
      @agent.set_proxy proxy_host, proxy_port
    end

    @agent.get(@site_url)

    form = fill_in_signin_form(@agent.page)

    response = @agent.submit form

    if response.code != "200"
      error "!!! HTTP Status: #{result.code} when attempting to sign in"
      result.response.each_pair { |header, value| error "#{header}: #{value}" }
      error result.pretty_inspect
      exit 2
    end
  end

  def fill_in_signin_form(page)
    form = page.form_with id: "new_user"
    form.field_with(name: "user[email]").value = @username
    form.field_with(name: "user[password]").value = @password
    form
  end

  def check_open_cases_list_page
    info '.. Smoketest check "All open cases" page has loaded'

    if @agent.page.at_css(".page-heading--primary").text != "Cases"
      error "All open cases page has not loaded"
      exit 2
    end
  end

  def view_random_case
    info ".. Smoketest check how many visible cases and view a random one"

    # get number of cases
    # pick a random number between 0 and no. of cases
    # Find the row and click on the link (grab case number)
    # check response = 200
    # Check page heading

    page = @agent.page
    case_records = page.css("table.report tbody tr")

    total_visible_cases = case_records.count
    random_row_number = Random.new.rand(0..(total_visible_cases - 1))
    selected_row = case_records[random_row_number]

    case_link = selected_row.at_css("a")
    @case_number  = case_link.text
    @case_summary = selected_row
                        .at_css('td[aria-label="Request detail"] strong')
                        .text.rstrip!

    response = @agent.click(case_link)

    if response.code != "200"
      error "!!! HTTP Status: #{result.code} when attempting to view case"
      result.response.each_pair { |header, value| error "#{header}: #{value}" }
      error result.pretty_inspect
      exit 2
    end
  end

  def check_case_details_page
    info '.. Smoketest check "Case details" page has loaded'
    if !@agent.page.at_css(".page-heading--primary").text.include?(@case_summary) &&
        !@agent.page.at_css(".page-heading--secondary").text.include?(@case_number)

      error "Case details page has not loaded"
      exit 2
    end
  end

  def info(message)
    puts message
  end

  def error(message)
    puts "!!! ERROR - #{message}"
  end
end
# rubocop:enable Rails/Exit
