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
                 time_limit_type: :string

  enum time_limit_type: {
         business_days: 'business_days',
         calendar_days: 'calendar_days'
       }

  validates_presence_of :name,
                        :abbreviation,
                        :escalation_time_limit,
                        :internal_time_limit,
                        :external_time_limit,
                        :time_limit_type,
                        on: :create

  has_many :cases,
           class_name: 'Case::Base'

  def self.foi
    find_by!(abbreviation: 'FOI')
  end

  def self.gq
    find_by!(abbreviation: 'GQ')
  end

  def self.sar
    find_by!(abbreviation: 'SAR')
  end

  def abbreviation_and_name
    "#{abbreviation} - #{name}"
  end
end
