module OverturnedICOParams
  extend ActiveSupport::Concern

  def create_overturned_ico_params
    params.require(:case_overturned_sar).permit(
        :original_ico_appeal_id,
        :original_case_id,
        :reply_method,
        :email,
        :postal_address,
        :received_date_dd, :received_date_mm, :received_date_yyyy,
        :external_deadline_dd, :external_deadline_mm, :external_deadline_yyyy,
        )
  end

end
