require 'rails_helper'

feature 'The internal deadline for each item is shown in the list view' do

  background do
    Timecop.freeze('21/08/2016') do
      create(:correspondence)
      create(:correspondence, category: create(:category, :gq))
    end
    login_as create(:user)
  end

  scenario 'for General Enquiries it is 10 working days, after the day of receipt' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('General enquiry') }
    rows.each { |row| expect(row.text.include?('05/09/16')).to be true }
  end

  scenario 'for Freedom of Information Requests it is 10 working days, after the day of receipt' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('Freedom of information request') }
    rows.each { |row| expect(row.text.include?('05/09/16')).to be true }
  end
end

feature 'The external deadline for each item is shown in the list view' do

  background do
    Timecop.freeze('21/08/2016') do
      create(:correspondence)
      create(:correspondence, category: create(:category, :gq))
    end
    login_as create(:user)
  end

  scenario 'for General Enquiries it is 10 working days, after the day of receipt' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('General enquiry') }
    rows.each { |row| expect(row.text.include?('12/09/16')).to be true }
  end

  scenario 'for Freedom of Information Requests it is 10 working days, after the day of receipt' do
    visit '/'
    rows = all('.report tr').select { |row| row.text.include?('Freedom of information request') }
    rows.each { |row| expect(row.text.include?('19/09/16')).to be true }
  end

end
