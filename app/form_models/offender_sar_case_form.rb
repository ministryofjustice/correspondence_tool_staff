module OffenderSARCaseForm
  extend ActiveSupport::Concern

  include OffenderFormValidators

  STEPS = %w[subject-details
             requester-details
             reason-rejected
             recipient-details
             requested-info
             request-details
             date-received].freeze

  def steps
    skip_reason_rejected_step(STEPS)
  end

private

  def skip_reason_rejected_step(steps)
    if !invalid_submission?
      steps = steps.reject { |x| x == "reason-rejected" }
    end
    steps
  end
end
