RSpec::Matchers.define :have_text(:all, do |expected|
  match do |actual|
    begin
      # return true or false here
      #
      Capybara.ignore_hidden_elements = false
      expect(actual).to have_text expected
    ensure
      Capybara.ignore_hidden_elements = true
    end
  end)
end
