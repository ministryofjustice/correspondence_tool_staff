module OffenderSARCaseForm
  extend ActiveSupport::Concern

  def steps
    %w[subject-details
       requester-details
       recipient-details
       requested-info
       request-details
       date-received].freeze
  end

end
