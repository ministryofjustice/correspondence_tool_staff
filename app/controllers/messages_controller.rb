class MessagesController < ApplicationController



  def create
    @case = Case.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)
    team = current_user.teams_for_case(@case).first
    redirect_to show_case_path(@case)
    @case.state_machine.add_message_to_case!(current_user, team, params['case']['message_text'])
  end
end