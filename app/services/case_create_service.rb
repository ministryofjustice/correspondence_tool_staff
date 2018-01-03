class CaseCreateService
  attr_reader :case, :params, :result, :user

  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    @case = Case::Base.new(params.merge(uploading_user: user))
    if params[:flag_for_disclosure_specialists].blank?
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
