module OverturnedICOParams
  extend ActiveSupport::Concern

  def create_ico_overturned_foi_params
    params
      .require(:case_overturned_foi)
      .permit(create_overturned_ico_params_list)
  end

  def create_ico_overturned_sar_params
    params
      .require(:case_overturned_sar)
      .permit(create_overturned_ico_params_list)
  end

  private

  def create_overturned_ico_params_list
    [
      :original_ico_appeal_id,
      :original_case_id,
      :reply_method,
      :email,
      :postal_address,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
    ]
  end

  def respond_overturned_params
    params.require(:case_overturned_foi).permit(
      :date_responded_dd,
      :date_responded_mm,
      :date_responded_yyyy,
    )
  end
end
