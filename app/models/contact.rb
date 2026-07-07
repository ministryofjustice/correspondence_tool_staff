# == Schema Information
#
# Table name: contacts
#
#  id                  :bigint           not null, primary key
#  name                :string
#  address_line_1      :string
#  address_line_2      :string
#  town                :string
#  county              :string
#  postcode            :string
#  data_request_emails :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  contact_type_id     :bigint
#  data_request_name   :string
#  escalation_name     :string
#  escalation_emails   :string
#
class Contact < ApplicationRecord
  include EmailValidatable

  before_validation :cleanse_emails
  after_update :sync_denormalised_locations, if: :saved_change_to_name?

  validates :name, presence: true
  validates :address_line_1, presence: true
  validates :postcode, presence: true
  validates :contact_type, presence: true
  validates :escalation_name, presence: true, if: :prison?
  validates :escalation_emails, presence: true, if: :prison?
  validates_emails_for :data_request_emails, multiple: true
  validates_emails_for :escalation_emails, multiple: true, if: :prison?

  belongs_to :contact_type, class_name: "CategoryReference", inverse_of: :contacts

  def address
    format_address("\n")
  end

  def inline_address
    format_address(", ")
  end

  def contact_type_display_value
    contact_type.value
  end

  def self.filter_by_contact_type(filters)
    filter_sql = "category_references.code IN (?)"
    joins(:contact_type).where(filter_sql, filters)
  end

  def self.search_by_contact_name(search_term)
    search_sql = "LOWER(name) LIKE ?"
    where(search_sql, "%#{search_term}%").order(:name)
  end

  def self.filtered_search_by_contact_name(filters, search_term)
    filter_by_contact_type(filters).search_by_contact_name(search_term)
  end

  def all_emails
    data_request_emails&.split("\n")
  end

  def prison?
    contact_type&.code == "prison"
  end

private

  def format_address(separator)
    [
      address_line_1,
      address_line_2,
      town,
      county,
      postcode,
    ].compact
     .reject(&:empty?)
     .join(separator)
  end

  def cleanse_emails
    self.data_request_emails = strip(data_request_emails)
    self.escalation_emails = strip(escalation_emails)
  end

  # DataRequestArea#location and DataRequest#location are denormalised from
  # the contact name; both must be updated here because update_all skips the
  # DataRequestArea callback that would otherwise cascade the change. Runs in
  # the same transaction as the rename so the tables can never disagree.
  def sync_denormalised_locations
    now = Time.current
    areas = DataRequestArea.where(contact_id: id)
    areas.update_all(location: name, updated_at: now)
    DataRequest.where(data_request_area_id: areas.select(:id)).update_all(location: name, updated_at: now)
  end

  def strip(email_list)
    return if email_list.blank?

    email_list.split.join("\n")
  end
end
