require 'rails_helper'

RSpec.describe DefaultUser, type: :model do

  subject(:default_user) { DefaultUser.build! }


  describe '#build!' do
    it { expect(default_user.id).to eq(-100) }
    it { expect(default_user.full_name).to eq '' }
    it { expect(default_user.roles).to eq [] }
    it { expect(default_user.send(:skip_full_name_check?)).to be true }
  end

  describe '#id='do
    it 'cannot be overriden with a different value' do
      default_user.id = 12345
      expect(default_user.id).to eq(-100)
    end
  end

  describe '#email='do
    it 'cannot be overriden with a different value' do
      default_user.email = 'a-different-email@digital.gov'
      expect(default_user.email).not_to eq 'a-different-email@digital.gov'
    end
  end
end
