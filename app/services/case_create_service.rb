class CaseCreateService
  attr_reader :case, :params, :result, :user

  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    case_class = params[:type].constantize
    @case = case_class.new(params.merge(uploading_user: user))

    if !@case.valid?
      @result = :error
    elsif @case.requires_flag_for_disclosure_specialists? && params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      @result = :error
    else
      if params[:flag_for_disclosure_specialists] == 'yes'
        @case.save!
        CaseFlagForClearanceService.new(
          user: user,
          kase: @case,
          team: BusinessUnit.dacu_disclosure
        ).call
        @result = :assign_responder
      else
        @case.save!
        @result = :assign_responder
      end
    end
    @result != :error
  end
end
