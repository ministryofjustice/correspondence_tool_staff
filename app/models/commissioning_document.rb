# == Schema Information
#
# Table name: commissioning_documents
#
#  id                   :bigint           not null, primary key
#  data_request_area_id :bigint
#  template_name        :enum
#  sent                 :boolean          default(FALSE)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  attachment_id        :bigint
#
class CommissioningDocument < ApplicationRecord
  TEMPLATE_TYPES = {
    mappa: CommissioningDocumentTemplate::Mappa,
    standard: CommissioningDocumentTemplate::Standard,
  }.freeze

  enum template_name: {
    cat_a: "cat_a",
    cctv: "cctv",
    cross_border: "cross_border",
    mappa: "mappa",
    pdp: "pdp",
    prison: "prison",
    probation: "probation",
    security: "security",
    telephone: "telephone",
    standard: "standard",
  }

  belongs_to :data_request_area
  belongs_to :data_request
  belongs_to :attachment, class_name: "CaseAttachment"

  validates :data_request_area, presence: true
  validates :data_request, presence: true, if: :has_no_request_area?
  validates :template_name, presence: true

  delegate :deadline, to: :template

  def document
    return unless valid?

    if attachment.present?
      attachment.to_string
    else
      Sablon.template(template.path).render_to_string(template.context)
    end
  end

  def filename
    return unless valid?

    if attachment.present?
      attachment.filename
    else
      "Day1_#{data_request_area.data_request_area_type}_#{case_number}_#{subject_name}_#{timestamp}.#{mime_type}"
    end
  end

  def mime_type
    :docx
  end

  def remove_attachment
    return if attachment.nil?

    attachment.destroy!
    self.attachment_id = nil
    save!
  end

  def has_no_request_area?
    self.data_request_area.nil?
  end

private

  def template
    TEMPLATE_TYPES[template_name.to_sym].new(data_request_area:)
  end

  def timestamp
    Time.current.strftime("%Y%m%dT%H%M")
  end

  def subject_name
    data_request_area.kase.subject_full_name.tr(" ", "-")
  end

  def case_number
    data_request_area.kase.number
  end
end
