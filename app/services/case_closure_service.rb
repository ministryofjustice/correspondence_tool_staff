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
      @result = :ok
    else
      @result = :error
    end
  end
end
