class CaseCreateService
  attr_reader :case, :params, :result, :user

  def initialize(user, case_class, params)
    @user       = user
    @case_class = case_class
    @params     = params
  end

  def call
    @case = @case_class.new(params.merge(uploading_user: user))

    if !@case.valid?
      @result = :error
    elsif @case.requires_flag_for_disclosure_specialists? && params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      @result = :error
    else
      @case.save!
      if params[:flag_for_disclosure_specialists] == 'yes'
        CaseFlagForClearanceService.new(
          user: user,
          kase: @case,
          team: BusinessUnit.dacu_disclosure
        ).call
      end
      @result = :assign_responder
    end
    @result != :error
  end
end
