class FeedbackController < ApplicationController
  def create
    @feedback = Feedback.new(create_feedback_params)

    respond_to do |format|
      @feedback.save!
      format.js
    end
  end

private

  def create_feedback_params
    params.require(:feedback).permit(
      :comment,
    ).merge({ email: current_user.email,
              user_agent: request.user_agent,
              referer: request.referer })
  end
end
