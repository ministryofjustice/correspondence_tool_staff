class MessagesController < ApplicationController

  def create
    @case = Case.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)
    team = current_user.teams_for_case(@case).first
    @case.state_machine.add_message_to_case!(current_user, team, params[:case][:message_text])
    redirect_to case_path(@case, anchor: 'messages-section')

  rescue ActiveRecord::RecordInvalid => err
    if err.record.errors.include?(:message)
      flash[:case_errors] = {  message_text: err.record.errors[:message] }
    end
    redirect_to case_path(@case, anchor: 'messages-section')
  end

end

