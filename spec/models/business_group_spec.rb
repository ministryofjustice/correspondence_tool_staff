require 'rails_helper'

RSpec.describe BusinessGroup, type: :model do
  it 'can be created' do
    bg = BusinessGroup.create name: 'Group Hugs',
                              email: 'group.hugs@localhost'
    expect(bg).to be_valid
  end

  it { should validate_absence_of(:parent_id) }

  it { should have_many(:directorates).with_foreign_key(:parent_id) }
end
