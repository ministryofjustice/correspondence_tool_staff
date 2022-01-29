class UpdateClosureService

  attr_reader :result

  def initialize(kase, user, params)
    @kase = kase
    @user = user
    @params = params
    @result = nil
  end

  def call
    if @kase.update(@params)
      add_ico_decision_files if @kase.ico? && @params[:uploaded_decision_files].present?

      @kase.state_machine.update_closure!(acting_user: @user,
                                          acting_team: @kase.team_for_unassigned_user(@user, find_user_role))
      @result = :ok

    else
      @result = :error
    end
  end

  private

  def add_ico_decision_files
    uploader = S3Uploader.new(@kase, @user)
    uploader.process_files(@params[:case_ico][:uploaded_ico_decision_files], :ico_decision)
  end

  def find_user_role
    if @kase.is_sar_internal_review? 
      return :approver if @user.approver?
    end

    @user.manager? ? :manager : :responder
  end
end
