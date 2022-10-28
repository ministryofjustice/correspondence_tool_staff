class CommissioningDocument
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  TEMPLATE_TYPES = {
    prison: "HMPS",
    security: "Security",
    probation: "Probation",
    cctv: "CCTV",
    mappa: "MAPPA",
    pdp: "PDP",
    cat_a: "CATA",
    cross_border: "TX",
  }.freeze

  def initialize(data_request:)
    @data_request = data_request
  end

  def template; end
end
