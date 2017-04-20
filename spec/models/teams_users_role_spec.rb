require 'rails_helper'

RSpec.describe TeamsUsersRole, type: :model do
  it 'can be created' do
    tur = TeamsUsersRole.create user: create(:user),
                                team: create(:team),
                                role: 'manager'
    expect(tur).to be_valid
  end

  it { should have_enum(:role).with_values(%w{manager responder approver}) }
  it { should belong_to(:user) }
  it { should belong_to(:team) }
end
