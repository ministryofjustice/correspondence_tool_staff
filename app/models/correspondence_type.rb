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
  # Deadlines should really get their own table and be parameterised on:
  #   correspondence_type_id
  #   name - (e.g. internal, external, final)
  #   days - number of days from the from_date
  #   from date - the date to calculate from, e.g. created, received, day_after_created, day_after_received, external_deadline
  #   business/calendar days - whether to calculate in business days or calendar days
  jsonb_accessor :properties,
                 internal_time_limit: :integer,
                 external_time_limit: :integer,
                 escalation_time_limit: :integer,
                 deadline_calculator_class: :string,
                 default_press_officer: :string,
                 default_private_officer: :string,
                 report_category_name: [:string, default: '']


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

  # Mapping of correspondence type to the available sub-classes that may be
  # created when creating that type of correspondence. e.g. when creating an
  # FOI they may choose between Standard, Timeliness review and Compliance
  # review.
  #
  # Defined here for now, but should really be configured somewhere more
  # sensible, like as a JSON property.
  SUB_CLASSES_MAP = {
    FOI: [Case::FOI::Standard,
          Case::FOI::TimelinessReview,
          Case::FOI::ComplianceReview],
    SAR: [Case::SAR],
    ICO: [Case::ICO::FOI,
          Case::ICO::SAR],
    OVERTURNED_SAR: [Case::OverturnedICO::SAR]
  }.with_indifferent_access.freeze

  def self.by_report_category
    CorrespondenceType.properties_where_not(report_category_name: '').properties_order(:report_category_name)
  end

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

  def sub_classes
    SUB_CLASSES_MAP[abbreviation]
  end
end
