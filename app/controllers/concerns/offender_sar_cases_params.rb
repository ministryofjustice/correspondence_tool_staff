module OffenderSARCasesParams
  extend ActiveSupport::Concern

  class InputValidationError < RuntimeError; end

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
      :request_method,
      :requester_reference,
      :current_state,
      uploaded_request_files: [],
      rejected_reasons: []
    )
  end

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
      :reason_for_lateness_id,
    )
  end

  def partial_case_flags_params
    params.require(:offender_sar).permit(
      :is_partial_case,
      :further_actions_required,
      :partial_case_letter_sent_dated_dd, :partial_case_letter_sent_dated_mm, :partial_case_letter_sent_dated_yyyy
    )
  end

  def sent_to_sscl_params
    params.require(:offender_sar).permit(
      :sent_to_sscl_at_dd, :sent_to_sscl_at_mm, :sent_to_sscl_at_yyyy,
      :remove_sent_to_sscl_reason
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
      error_message = t("alerts.offender_sar.reason_for_lateness.blank")
    else
      reason = @reasons_for_lateness[reason_params["reason_for_lateness_id"].to_i]
      if reason.present?
        if reason == "other" && reason_params["reason_for_lateness_note"].blank?
          error_message = t("alerts.offender_sar.reason_for_lateness.blank")
        end
      else
        error_message = t("alerts.offender_sar.reason_for_lateness.invalid")
      end
    end
    raise InputValidationError, error_message unless error_message.nil?
  end
end
