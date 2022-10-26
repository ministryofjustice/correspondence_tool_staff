class CommissioningDocument
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

TEMPLATE_TYPES = %i[
    prison
    security
    probation
    cctv
    mappa
    pdp
    cat_a
    cross_border
  ].freeze

  def initialize(data_request:)
    @data_request = data_request
  end

  def document_type; end
end
