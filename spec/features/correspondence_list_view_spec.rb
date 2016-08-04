require 'rails_helper'

feature 'a user can see all correspondence on the system' do

  background do
    create_list(:correspondence, 10)
  end

  scenario 'in a single list' do
    visit '/'
    Correspondence.all.each do |correspondence|
      expect(page).to have_content(correspondence.created_at.strftime("%d/%m/%y"))
      expect(page).to have_content(correspondence.category.humanize)
      expect(page).to have_content(correspondence.topic.humanize)
    end
  end
end
