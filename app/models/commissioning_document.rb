# == Schema Information
#
# Table name: commissioning_documents
#
#  id              :bigint           not null, primary key
#  data_request_id :bigint
#  template_name   :enum
#  sent            :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  attachment_id   :bigint
#
class CommissioningDocument < ApplicationRecord
  TEMPLATE_TYPES = {
    cat_a: CommissioningDocumentTemplate::CatA,
    cctv: CommissioningDocumentTemplate::Cctv,
    cross_border: CommissioningDocumentTemplate::CrossBorder,
    mappa: CommissioningDocumentTemplate::Mappa,
    pdp: CommissioningDocumentTemplate::Pdp,
    prison: CommissioningDocumentTemplate::Prison,
    probation: CommissioningDocumentTemplate::Probation,
    security: CommissioningDocumentTemplate::Security,
    telephone: CommissioningDocumentTemplate::Telephone,
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
  }

  belongs_to :data_request_area
  belongs_to :attachment, class_name: "CaseAttachment"

  validates :data_request, presence: true
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
      "Day1_#{request_type}_#{case_number}_#{subject_name}_#{timestamp}.#{mime_type}"
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

private

  def template
    TEMPLATE_TYPES[template_name.to_sym].new(data_request:)
  end

  def request_type
    debugger
    @data_request_area = DataRequestArea.find(params[:id])
    @data_request_area.data_request_area_type

    # template.request_type
  end

  def timestamp
    Time.current.strftime("%Y%m%dT%H%M")
  end

  def subject_name
    data_request.kase.subject_full_name.tr(" ", "-")
  end

  def case_number
    data_request.kase.number
  end
end
