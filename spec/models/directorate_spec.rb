# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#  role       :string
#  code       :string
#  deleted_at :datetime
#

require "rails_helper"

RSpec.describe Directorate, type: :model do
  it "can be created" do
    di = described_class.create! name: "The Directors",
                                 email: "the.directors@localhost",
                                 parent_id: 1
    expect(di).to be_valid
  end

  it { is_expected.to validate_presence_of(:parent_id) }

  it { is_expected.to belong_to(:business_group).with_foreign_key(:parent_id) }
  it { is_expected.to have_many(:business_units).with_foreign_key(:parent_id) }
end
