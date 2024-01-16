module OffenderSARCaseForm
  extend ActiveSupport::Concern

  include OffenderFormValidators

  def steps
    %w[subject-details
       requester-details
       reason-rejected
       recipient-details
       requested-info
       request-details
       date-received].freeze
  end
end
