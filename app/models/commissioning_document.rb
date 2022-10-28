class CommissioningDocument
  include ActiveModel::Conversion
  extend  ActiveModel::Naming
  include ActiveModel::Validations

  TEMPLATE_TYPES = {
    prison: CommissioningDocumentTemplate::Prison,
    security: CommissioningDocumentTemplate::Security,
    probation: CommissioningDocumentTemplate::Probation,
    cctv: CommissioningDocumentTemplate::Cctv,
    mappa: CommissioningDocumentTemplate::Mappa,
    pdp: CommissioningDocumentTemplate::Pdp,
    cat_a: CommissioningDocumentTemplate::CatA,
    cross_border: CommissioningDocumentTemplate::CrossBorder,
  }.freeze

  attr_accessor :template_name

  validates :template_name, presence: true, inclusion: { in: CommissioningDocument::TEMPLATE_TYPES.keys }

  def initialize(data_request:)
    @data_request = data_request
  end

  def document
    return unless valid?

    Sablon.template(template.path).render_to_string(template.context)
  end

  def filename
    return unless valid?

    "Day1_#{request_type}_#{case_number}_#{subject_name}_#{timestamp}.#{mime_type}"
  end

  def mime_type
    :docx
  end

  private

  def template
    TEMPLATE_TYPES[@template_name].new(data_request: @data_request)
  end

  def request_type
    template.request_type
  end

  def timestamp
    Time.current.strftime('%Y%m%dT%H%M')
  end

  def subject_name
    @data_request.kase.subject_full_name.tr(' ', '-')
  end

  def case_number
    @data_request.kase.number
  end
end
