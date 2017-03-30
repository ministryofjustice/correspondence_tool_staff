require 'mechanize'

class SmokeTest

  def initialize(url, user_email, user_password)
    @url = url
    @user_email = user_email
    @user_password = user_password
    @agent = Mechanize.new
  end

  def run
    login_page = get_login_page
    case_list_page = login(login_page)
    check_case_list_page(case_list_page)
  end

  private

  def get_login_page
    page = @agent.get(@url)
    forgotten_password_link = page.link_with(text: 'Forgot your password?')
    if forgotten_password_link.nil?
      raise "Unable to find Forgotten Password link on Login page at #{@url}"
    end
    page
  end

  def login(page)
    login_form = page.forms.first
    login_form['user[email]'] = @user_email
    login_form['user[password]'] = @user_password
    _case_list_page = @agent.submit(login_form, login_form.buttons.first)
  end

  def check_case_list_page(page)
    if page.title != 'GOV.UK - The best place to find government services and information'
      raise "Unexpected title on Case list page"
    end
    new_case_button = page.links_with(:text => 'New case').first
    raise "Unable to find New Case button on Case list page. Is this the expected URL? #{page.uri}" if new_case_button.nil?
  end
end


url = ARGV[0]
user = ARGV[1]
pwd = ARGV[2]
SmokeTest.new(url, user, pwd).run
