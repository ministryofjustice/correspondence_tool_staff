class CaseSendBackService

  attr_accessor :result, :error_message

  def initialize(user:, kase:, comment:)
    @user = user
    @kase = kase
    @result = :incomplete
    @error_message = nil 
    @comment = comment
  end

  def call
    begin
      process_send_back
      @result = :ok
    rescue ConfigurableStateMachine::InvalidEventError  => err
      @error_message = "Error processing sending back: #{err.message}"
      Rails.logger.error(@error_message)
      @result = :error
    end
  end

  private

  def process_send_back
    ActiveRecord::Base.transaction do
      if @comment.present?
        @kase.state_machine.add_message_to_case!(
          acting_user: @user,
          acting_team: @user.case_team(@kase),
          message: @comment, 
          disable_hook: true)
      end
      @kase.state_machine.send_back!(
        acting_user: @user, 
        acting_team: @user.case_team(@kase),
      )
    end
  end

end
