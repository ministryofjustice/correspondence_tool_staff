# @note: Case Closure and Respond methods require refactoring as per
# other case behaviours
module Notable
  extend ActiveSupport::Concern
  include SetupCase

  def add_message(event_name: '', on_success: '')
    begin
      @case.state_machine.send(event_name,
        acting_user: current_user,
        acting_team: case_team,
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

  # need to sort with manager first so that if we are both manager and something else, we don't
  # try to execute the action with our lower authority (which might fail)
  def case_team
    User.sort_teams_by_roles(case_teams).first
  end

  def case_teams
    if current_user.teams_for_case(@case).any?
      current_user.teams_for_case(@case)
    else
      current_user.teams
    end
  end

  def set_case
    @case = Case::Base.find(params[:case_id])
  end
end
