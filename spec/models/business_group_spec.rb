# == Schema Information
#
# Table name: teams
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  email            :citext
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  type             :string
#  parent_id        :integer
#  role             :string
#  code             :string
#  deleted_at       :datetime
#  moved_to_unit_id :integer
#

require "rails_helper"

RSpec.describe BusinessGroup, type: :model do
  it "can be created" do
    bg = described_class.create! name: "Group Hugs",
                                 email: "group.hugs@localhost"
    expect(bg).to be_valid
  end

  it { is_expected.to validate_absence_of(:parent_id) }

  it { is_expected.to have_many(:directorates).with_foreign_key(:parent_id) }

  it { is_expected.to have_many(:business_units).through(:directorates) }
end
