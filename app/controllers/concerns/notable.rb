# @note: Case Closure and Respond methods require refactoring as per
# other case behaviours
module Notable
  extend ActiveSupport::Concern
  include SetupCase

  def add_message(event_name: '', on_success: '')
    begin
      @case.state_machine.send(event_name,
        acting_user: current_user,
        acting_team: current_user.case_team(@case),
        message: params[:case][:message_text]
      )
    rescue ActiveRecord::RecordInvalid => err
      if err.record.errors.include?(:message)
        flash[:case_errors] = { message_text: err.record.errors[:message] }
      end
    ensure
      redirect_to on_success
    end
  end

  private

  def set_case
    @case = Case::Base.find(params[:case_id])
  end
end
