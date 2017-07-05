class MessagesController < ApplicationController



  def create
    @case = Case.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)
    team = current_user.teams_for_case(@case).first
    @case.state_machine.add_message_to_case!(current_user, team, params['case']['message'])
    redirect_to show_case_path(@case)
  end
end