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

  it { should have_attributes(default_press_officer: nil,
                              default_private_officer: nil)}

  describe 'deadline_calculator_class' do
    it { should validate_presence_of(:deadline_calculator_class) }
    it 'allows the value CalendarDays' do
      ct = CorrespondenceType.new name: 'Calendar Days Test',
                                  abbreviation: 'CDT',
                                  escalation_time_limit: 1,
                                  internal_time_limit: 1,
                                  external_time_limit: 1,
                                  deadline_calculator_class: 'CalendarDays'
      expect(ct).to be_valid
    end

    it 'allows the value BusinessDays' do
      ct = CorrespondenceType.new name: 'Business Days Test',
                                  abbreviation: 'BDT',
                                  escalation_time_limit: 1,
                                  internal_time_limit: 1,
                                  external_time_limit: 1,
                                  deadline_calculator_class: 'BusinessDays'
      expect(ct).to be_valid
    end

    it 'does not allow other values' do
      expect {
        CorrespondenceType.new name: 'Invalid Class Test',
                               abbreviation: 'IDT',
                               escalation_time_limit: 1,
                               internal_time_limit: 1,
                               external_time_limit: 1,
                               deadline_calculator_class: 'Invalid Class'
      }.to raise_error(ArgumentError)
    end
  end
end
