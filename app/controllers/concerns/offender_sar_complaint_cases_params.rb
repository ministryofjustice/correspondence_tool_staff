module OffenderSARComplaintCasesParams
  extend ActiveSupport::Concern

  def create_offender_sar_complaint_params
    params.require(:offender_sar_complaint).permit(
      :case_reference_number,
      :complaint_type,
      :complaint_subtype,
      :email,
      :requester_reference,
      :flag_as_high_profile,
      :flag_as_dps_missing_data,
      :gld_contact_name,
      :gld_contact_email,
      :gld_contact_phone,
      :gld_reference,
      :ico_contact_name,
      :ico_contact_email,
      :ico_contact_phone,
      :ico_reference,
      :message,
      :name,
      :number_final_pages,
      :number_exempt_pages,
      :other_subject_ids,
      :postal_address,
      :priority,
      :prison_number,
      :previous_case_numbers,
      :probation_area,
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
      :original_case_number,
      :original_case_id,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
      :appeal_outcome_id,
      :outcome_id,
      :total_cost,
      :settlement_cost,
      approval_flag_ids: []
    )
  end

  # @todo: Replace with appropriate edit params
  def update_offender_sar_complaint_params
    create_offender_sar_complaint_params
  end

  def process_offender_sar_complaint_closure_params
    params.require(:offender_sar_complaint).permit(
      :info_held_status_abbreviation,
    )
  end

  def respond_offender_sar_complaint_params
    params.require(:offender_sar_complaint).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end

  def reopen_offender_sar_complaint_params
    params.require(:offender_sar_complaint).permit(
      :external_deadline_dd,
      :external_deadline_mm,
      :external_deadline_yyyy,
    )
  end
end
