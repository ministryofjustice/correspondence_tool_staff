# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Team, type: :model do
  it 'can be created' do
    bu = Team.create name: 'Busy Units', email: 'busy.units@localhost'
    expect(bu).to be_valid
  end

  it { should have_many(:user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:users).through(:user_roles) }
  it { should have_many(:responder_user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:responders).through(:responder_user_roles) }
  it { should have_many(:manager_user_roles)
                .class_name('TeamsUsersRole') }
  it { should have_many(:managers).through(:manager_user_roles) }

  it 'has a working factory' do
    expect(create :team).to be_valid
  end
end
