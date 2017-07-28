require 'rails_helper'

RSpec.describe Directorate, type: :model do
  it 'can be created' do
    di = Directorate.create name: 'The Directors',
                            email: 'the.directors@localhost',
                            parent_id: 1
    expect(di).to be_valid
  end

  it { should validate_presence_of(:parent_id) }

  it { should belong_to(:business_group).with_foreign_key(:parent_id) }
  it { should have_many(:business_units).with_foreign_key(:parent_id) }
end
