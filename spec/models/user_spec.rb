require 'rails_helper'

RSpec.describe User, type: :model do

  subject { create(:user) }

  it_behaves_like 'roles', described_class, User::ROLES

  it { should have_many(:assignments) }
  it { should have_many(:cases)       }

end
