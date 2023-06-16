module OverturnedICOParams
  extend ActiveSupport::Concern

  def create_ico_overturned_foi_params
    params
      .require(:overturned_foi)
      .permit(create_overturned_ico_params_list)
      .merge(original_case_params(params[:overturned_foi]))
  end

  def create_ico_overturned_sar_params
    params
      .require(:overturned_sar)
      .permit(create_overturned_ico_params_list)
      .merge(original_case_params(params[:overturned_sar]))
  end

  def respond_overturned_params
    params.require(@correspondence_type_key).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end

private

  def create_overturned_ico_params_list
    %i[
      original_ico_appeal_id
      reply_method
      email
      postal_address
      external_deadline_dd
      external_deadline_mm
      external_deadline_yyyy
      flag_for_disclosure_specialists
    ]
  end

  def original_case_params(case_params)
    ico_appeal = Case::ICO::Base.find(case_params[:original_ico_appeal_id])
    {
      original_case_id: ico_appeal.original_case_id,
      received_date_dd: ico_appeal.date_ico_decision_received_dd,
      received_date_mm: ico_appeal.date_ico_decision_received_mm,
      received_date_yyyy: ico_appeal.date_ico_decision_received_yyyy,
    }
  end
end
