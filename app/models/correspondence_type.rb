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
                 report_category_name: [:string, { default: "" }],
                 extension_time_limit: :integer,
                 extension_time_default: :integer,
                 show_on_menu: [:boolean, { default: true }],
                 display_order: [:integer, { default: nil }]

  enum :deadline_calculator_class, {
    "BusinessDays" => "BusinessDays",
    "CalendarDays" => "CalendarDays",
    "CalendarMonths" => "CalendarMonths",
  }

  validates :name,
            :abbreviation,
            :escalation_time_limit,
            :internal_time_limit,
            :external_time_limit,
            :deadline_calculator_class,
            presence: { on: :create }

  has_many :correspondence_type_roles,
           -> { distinct },
           class_name: "TeamCorrespondenceTypeRole"
  has_many :teams,
           through: :correspondence_type_roles

  scope :menu_visible, -> { where("properties->>'show_on_menu' = 'true'") }

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
    SAR: [Case::SAR::Standard],
    SAR_INTERNAL_REVIEW: [Case::SAR::InternalReview],
    OFFENDER_SAR: [Case::SAR::Offender],
    OFFENDER_SAR_COMPLAINT: [Case::SAR::OffenderComplaint],
    ICO: [Case::ICO::FOI,
          Case::ICO::SAR],
    OVERTURNED_SAR: [Case::OverturnedICO::SAR],
    OVERTURNED_FOI: [Case::OverturnedICO::FOI],
  }.with_indifferent_access.freeze

  # Keep a cache of all (6!) items to prevent endless N+1 queries using this tiny class
  class << self
    # rubocop:disable Naming/MemoizedInstanceVariableName
    def all_cached
      @all ||= all
    end

    def clear_cache
      @all = nil
    end
    # rubocop:enable Naming/MemoizedInstanceVariableName

    # This method is used by Case::Base to find its correspondence type
    def find_by_abbreviation!(abbreviation)
      all_cached.detect { |ct| ct.abbreviation == abbreviation } || super
    end
  end

  # Invalidate the cache after saving a change
  after_save do
    self.class.clear_cache
  end

  def self.by_report_category
    # CorrespondenceType.properties_where_not(report_category_name: '').properties_order(:report_category_name)
    CorrespondenceType.properties_where_not(report_category_name: "").order(Arel.sql("(correspondence_types.properties -> 'report_category_name') asc"))
  end

  def self.foi
    find_by_abbreviation! "FOI"
  end

  def self.gq
    find_by_abbreviation! "GQ"
  end

  def self.sar
    find_by_abbreviation! "SAR"
  end

  def self.offender_sar
    find_by_abbreviation! "OFFENDER_SAR"
  end

  def self.offender_sar_complaint
    find_by_abbreviation! "OFFENDER_SAR_COMPLAINT"
  end

  def self.ico
    find_by_abbreviation! "ICO"
  end

  def self.overturned_sar
    find_by_abbreviation! "OVERTURNED_SAR"
  end

  def self.overturned_foi
    find_by_abbreviation! "OVERTURNED_FOI"
  end

  def self.sar_internal_review
    find_by_abbreviation! "SAR_INTERNAL_REVIEW"
  end
  # rubocop:enable Rails/DynamicFindBy

  def abbreviation_and_name
    "#{abbreviation.tr('_', '-')} - #{name}"
  end

  def sub_classes
    SUB_CLASSES_MAP[abbreviation]
  end

  def self.custom_reporting_types
    by_report_category
  end

  def shortname
    abbreviation.humanize
  end
end
