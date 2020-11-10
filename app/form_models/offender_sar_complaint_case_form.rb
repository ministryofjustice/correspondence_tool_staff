module OffenderSARComplaintCaseForm
  include OffenderSARCaseForm
  # @todo: Should these steps be defined in 'Steppable' or the controller
  def steps
    %w[subject-details
       requester-details
       recipient-details
       requested-info
       request-details
       date-received].freeze
  end
end
