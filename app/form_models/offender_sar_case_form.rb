module OffenderSarCaseForm
  extend ActiveSupport::Concern

  include OffenderFormValidators

  def steps
    %w[subject-details
       requester-details
       recipient-details
       requested-info
       request-details
       date-received].freeze
  end
end
