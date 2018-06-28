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

class CorrespondenceType < ApplicationRecord

  jsonb_accessor :properties,
                 internal_time_limit: :integer,
                 external_time_limit: :integer,
                 escalation_time_limit: :integer,
                 deadline_calculator_class: :string,
                 default_press_officer: :string,
                 default_private_officer: :string

  enum deadline_calculator_class: {
         'BusinessDays' => 'BusinessDays',
         'CalendarDays' => 'CalendarDays',
       }

  validates_presence_of :name,
                        :abbreviation,
                        :escalation_time_limit,
                        :internal_time_limit,
                        :external_time_limit,
                        :deadline_calculator_class,
                        on: :create

  has_many :correspondence_type_roles,
           -> { distinct },
           class_name: 'TeamCorrespondenceTypeRole'
  has_many :teams,
           through: :correspondence_type_roles

  def self.foi
    find_by!(abbreviation: 'FOI')
  end

  def self.gq
    find_by!(abbreviation: 'GQ')
  end

  def self.sar
    find_by!(abbreviation: 'SAR')
  end

  def self.ico
    find_by!(abbreviation: 'ICO')
  end

  def abbreviation_and_name
    "#{abbreviation.tr('_', '-')} - #{name}"
  end
end
