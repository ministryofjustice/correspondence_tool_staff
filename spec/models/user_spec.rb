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
#  roles                  :string
#  full_name              :string
#

require 'rails_helper'

RSpec.describe User, type: :model do

  subject { create(:user) }

  it_behaves_like 'roles', described_class, User::ROLES

  it { should have_many(:assignments) }
  it { should have_many(:cases)       }
  it { should validate_presence_of(:full_name) }

end
