class MessagesController < ApplicationController

  def create
    @case = Case::Base.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)

    begin
      @case.state_machine.add_message_to_case!(
        acting_user: current_user,
        acting_team: case_team,
        message: params[:case][:message_text]
      )
    rescue ActiveRecord::RecordInvalid => err
      if err.record.errors.include?(:message)
        flash[:case_errors] = { message_text: err.record.errors[:message] }
      end
    ensure
      redirect_to case_path(@case, anchor: 'messages-section')
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

end
