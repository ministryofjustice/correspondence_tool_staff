require 'rails_helper'

feature 'The internal deadline for each item is show in the list view' do

  background do
    Timecop.freeze('21/08/2016 16:00') do
      create(:correspondence)
      create(:correspondence, category: create(:category, name: 'General enquiries'))
    end
    login_as create(:user)
  end

  scenario 'for General Enquiries it is 10 working days' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('General enquiries') }
    rows.each { |row| expect(row.text.include?('05/09/2016')).to be true }
  end

  scenario 'for Freedom of Information Requests it is 10 working days' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('Freedom of information request') }
    rows.each { |row| expect(row.text.include?('12/09/2016')).to be true }
  end
end
