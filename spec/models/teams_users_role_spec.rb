# == Schema Information
#
# Table name: teams_users_roles
#
#  id      :integer          not null, primary key
#  team_id :integer
#  user_id :integer
#  role    :enum             not null
#

require "rails_helper"

RSpec.describe TeamsUsersRole, type: :model do
  it "can be created" do
    tur = described_class.create! user: create(:user),
                                  team: create(:business_unit),
                                  role: "manager"
    expect(tur).to be_valid
  end

  it { is_expected.to have_enum(:role).with_values(%w[manager responder approver admin team_admin]) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:team).with_foreign_key(:team_id) }
end
