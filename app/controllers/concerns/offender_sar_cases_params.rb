module OffenderSARCasesParams
  extend ActiveSupport::Concern

  class InputValidationError < RuntimeError; end

  #rubocop:disable Metrics/MethodLength
  def create_offender_sar_params
    params.require(:offender_sar).permit(
      :case_reference_number,
      :delivery_method,
      :date_of_birth_dd, :date_of_birth_mm, :date_of_birth_yyyy,
      :requester_reference,
      :flag_as_high_profile,
      :message,
      :name,
      :number_final_pages,
      :number_exempt_pages,
      :other_subject_ids,
      :postal_address,
      :prison_number,
      :previous_case_numbers,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :recipient,
      :requester_type,
      :subject,
      :subject_address,
      :subject_aliases,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_name,
      :third_party_relationship,
      :third_party_company_name,
      :date_responded_dd, :date_responded_mm, :date_responded_yyyy,
      :date_of_birth_dd, :date_of_birth_mm, :date_of_birth_yyyy,
      :request_dated_dd, :request_dated_mm, :request_dated_yyyy,
      :requester_reference,
      uploaded_request_files: [],
      )
  end
  #rubocop:enable Metrics/MethodLength

  # @todo: Replace with appropriate edit params
  def update_offender_sar_params
    create_offender_sar_params
  end

  def process_offender_sar_closure_params
    params.require(:offender_sar).permit(
      :info_held_status_abbreviation,
    )
  end

  def record_reason_params
    params.require(:offender_sar).permit(
      :reason_for_lateness_note,
      :reason_for_lateness_id
      )
  end


  def respond_offender_sar_params
    params.require(:offender_sar).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      )
  end

  def validate_reason(reason_params)
    error_message = nil
    if reason_params.empty?
      error_message = 'Please choose the reason for lateness'
    else
      reason = @reasons_for_lateness[reason_params["reason_for_lateness_id"].to_i]
      if reason.present? 
        if reason == "other" && reason_params["reason_for_lateness_note"].blank?
          error_message = "Please provide the detail of the reason"
        end
      else
        error_message = "Invalid reason"
      end
    end
    raise InputValidationError.new(error_message) unless error_message.nil?
  end

end
