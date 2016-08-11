require 'rails_helper'

feature 'a user can see all correspondence on the system' do

  background do
    create_list(:correspondence, 10)
  end

  scenario 'in a single list' do
    login_as create(:user)
    visit '/'
    Correspondence.all.each do |correspondence|
      expect(page).to have_content(correspondence.created_at.strftime("%d/%m/%y"))
      expect(page).to have_content(correspondence.category.name.humanize)
      expect(page).to have_content(correspondence.topic.humanize)
    end
  end
end
