# == Schema Information
#
# Table name: correspondence_types
#
#  id           :integer          not null, primary key
#  name         :string
#  abbreviation :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  properties   :jsonb
#

require 'rails_helper'

describe CorrespondenceType, type: :model do

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:abbreviation) }
  it { should validate_presence_of(:escalation_time_limit) }
  it { should validate_presence_of(:internal_time_limit) }
  it { should validate_presence_of(:external_time_limit) }
end
