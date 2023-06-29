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
                                          acting_team: @user.case_team_for_event(@kase, "update_closure"))
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
end
