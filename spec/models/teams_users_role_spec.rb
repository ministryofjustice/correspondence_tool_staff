# == Schema Information
#
# Table name: teams_users_roles
#
#  id      :integer          not null, primary key
#  team_id :integer
#  user_id :integer
#  role    :enum             not null
#

require 'rails_helper'

RSpec.describe TeamsUsersRole, type: :model do
  it 'can be created' do
    tur = TeamsUsersRole.create user: create(:user),
                                team: create(:business_unit),
                                role: 'manager'
    expect(tur).to be_valid
  end

  it { should have_enum(:role).with_values(%w{manager responder approver admin team_admin}) }
  it { should belong_to(:user) }
  it { should belong_to(:team) }
end
