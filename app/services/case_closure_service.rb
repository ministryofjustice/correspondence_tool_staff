class CaseClosureService

  attr_reader :result, :flash_message

  def initialize(kase, user, params)
    @kase = kase
    @user = user
    @params = params
    @result = nil
  end

  def call
    @kase.prepare_for_close
    if @kase.update(@params)
      @kase.close(@user)
      @flash_message = I18n.t('notices.case_closed')
      add_ico_decision_files if @kase.ico?
      add_retention_schedule
      @result = :ok
    else
      @result = :error
    end
  end

  private

  def add_retention_schedule
    if FeatureSet.branston_retention_scheduling.enabled?
      service = RetentionSchedules::PlannedErasureDateService.new(kase: @kase)
      service.call
    end
  end

  def add_ico_decision_files
    if @params[:uploaded_ico_decision_files].present?
      uploader = S3Uploader.new(@kase, @user)
      uploader.process_files(@params[:uploaded_ico_decision_files], :ico_decision)
    end
  end
end
