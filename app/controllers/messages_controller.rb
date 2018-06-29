class MessagesController < ApplicationController

  def create
    @case = Case::Base.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)
    if current_user.teams_for_case(@case).any?
      teams = current_user.teams_for_case(@case)
    else
      teams = current_user.teams
    end
    weightings = { 'manager' => 100, 'approver' => 200, 'responder' => 300 }
    team = teams.sort{ |a, b| weightings[a.role] <=> weightings[b.role] }.first

    @case.state_machine.add_message_to_case!(
                                              acting_user: current_user,
                                              acting_team: team,
                                              message: params[:case][:message_text])

    redirect_to case_path(@case, anchor: 'messages-section')

  rescue ActiveRecord::RecordInvalid => err
    if err.record.errors.include?(:message)
      flash[:case_errors] = {  message_text: err.record.errors[:message] }
    end
    redirect_to case_path(@case, anchor: 'messages-section')
  end

end
