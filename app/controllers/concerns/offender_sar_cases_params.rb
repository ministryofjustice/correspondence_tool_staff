module OffenderSARCasesParams
  extend ActiveSupport::Concern

  def create_offender_sar_params
    params.require(:offender_sar).permit(
      :criminal_record_reference_number,
      :delivery_method,
      :date_of_birth_dd, :date_of_birth_mm, :date_of_birth_yyyy,
      :email,
      :flag_as_high_profile,
      :message,
      :name,
      :other_subject_ids,
      :postal_address,
      :prison_number,
      :previous_case_numbers,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :requester_type,
      :subject,
      :subject_aliases,
      :subject_full_name,
      :subject_type,
      :third_party,
      :third_party_relationship,
      :third_party_reference,
      :third_party_company_name,
      :reply_method,
      uploaded_request_files: [],
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

  def respond_offender_sar_params
    params.require(:offender_sar).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
      )
  end
end
