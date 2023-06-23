class MarkResponseAsSentService
  attr_reader :result

  def initialize(kase, user, params)
    @kase = kase
    @params = params
    @user = user
    @result = nil
  end

  def call
    ActiveRecord::Base.transaction do
      @kase.prepare_for_respond
      @kase.ico? ? respond_to_ico : respond_to_non_ico
    end
  end

private

  def respond_to_ico
    @kase.update(@params) # rubocop:disable Rails/SaveBang
    if !@kase.valid?
      @result = :error
    elsif @kase.responded_late?
      @result = :late
    else
      @kase.respond(@user)
      @result = :ok
    end
  end

  def respond_to_non_ico
    if @kase.update(@params)
      @kase.respond(@user)
      @result = :ok
    else
      @result = :error
    end
  end
end
