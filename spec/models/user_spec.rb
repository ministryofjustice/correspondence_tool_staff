# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#

require 'rails_helper'

RSpec.describe User, type: :model do

  subject { create(:user) }

  it { should have_many(:assignments) }
  it { should have_many(:cases)       }
  it { should validate_presence_of(:full_name) }
  it { should have_many(:team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:teams).through(:team_roles) }
  it { should have_many(:managing_team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:responding_team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:approving_team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:managing_teams).through(:managing_team_roles) }
  it { should have_many(:responding_teams).through(:responding_team_roles) }
  it { should have_many(:approving_teams).through(:approving_team_roles) }

  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:approver)  { create :approver }

  describe '#manager?' do
    it 'returns true for a manager' do
      expect(manager.manager?).to be true
    end

    it 'returns false for a responder' do
      expect(responder.manager?).to be false
    end

    it 'returns false for an approver' do
      expect(approver.manager?).to be false
    end
  end

  describe '#responder?' do
    it 'returns false for a manager' do
      expect(manager.responder?).to be false
    end

    it 'returns true for a responder' do
      expect(responder.responder?).to be true
    end

    it 'returns false for an approver' do
      expect(approver.responder?).to be false
    end
  end

  describe '#approver?' do
    it 'returns false for a manager' do
      expect(manager.approver?).to be false
    end

    it 'returns false for a responder' do
      expect(responder.approver?).to be false
    end

    it 'returns true for an approver' do
      expect(approver.approver?).to be true
    end
  end
end
