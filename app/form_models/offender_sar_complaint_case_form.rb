module OffenderSARComplaintCaseForm
  extend ActiveSupport::Concern
  
  include OffenderSARFormHelper

  STEPS = %w[link-offender-sar-case
    confirm-offender-sar
    requester-details
    recipient-details
    requested-info
    request-details
    date-received].freeze

  # @todo: Should these steps be defined in 'Steppable' or the controller
  def steps
    STEPS
  end


  private

  def validate_link_offender_sar_case(params)
    original_case_number = params[:original_case_number].strip
    case_link = LinkedCase.new(
      linked_case_number: original_case_number,
      type: :original
    )
    if case_link.valid?
      original_case = case_link.linked_case
      if not Pundit.policy(object.creator, original_case).show?
        @linked_case_error = helpers.translate_for_case(
          "Case::SAR::OffenderComplaint",
          'activerecord.errors.models',
          "original_case_number.not_authorised",
          {}
        )
      else
        object.original_case_id = original_case.id
      end
    else
      @linked_case_error = case_link.errors.details[:linked_case_number].first[:error]
    end
  end

  def params_after_step_link_offender_sar_case(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)

    params
  end

  def params_after_step_confirm_offender_sar(params)
    params.merge!(original_case_id: object.original_case_id)
    params.delete(:original_case_number)
    fields_subject_details = [
      "subject_full_name", 
      "subject_type", 
      "subject_aliases", 
      "subject_address", 
      "prison_number", 
      "other_subject_ids", 
      "recipient", 
      "third_party_relationship", 
      "third_party", 
      "third_party_company_name", 
      "third_party_name", 
      "postal_address", 
      "flag_as_high_profile",
      "date_of_birth"
    ]
    fields_subject_details.each do | single_field |
      params[single_field] = object.original_case.send(single_field)
    end 
    params
  end

end
