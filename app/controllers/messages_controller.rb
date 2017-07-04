class MessagesController < ApplicationController



  def create
    puts ">>>>>>>>>>>>>> ADD MESSAGE #{__FILE__}:#{__LINE__} <<<<<<<<<<<<<<<<<\n"
    ap params
    @case = Case.find params[:case_id]
    authorize(@case, :can_add_message_to_case?)

    @case.state_machine.add_message_to_case!(current_user, params['case']['message'])
    redirect_to show_case_path(@case)
  end
end