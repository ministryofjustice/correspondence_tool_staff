# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe CaseAttachment, type: :model do
  describe 'type enum' do
    it { should have_enum(:type).with_values ['response'] }
  end
end
