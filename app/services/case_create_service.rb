class CaseCreateService
  attr_reader :case, :params, :result, :user

  def initialize(user, params)
    @user = user
    @params = params
  end

  def call
    @case = Case.new(params.merge(uploading_user: user))
    if params[:flag_for_disclosure_specialists].blank?
      @case.valid?
      @case.errors.add(:flag_for_disclosure_specialists, :blank)
      @result = :error
    elsif @case.valid?
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
    else
      @result = :error
    end
    @result != :error
  end

  def get_class_from_case_type(case_type)
    case case_type
    when 'FoiTimelinessReview'
      FoiTimelinessReview
    when 'FoiComplianceReview'
      FoiComplianceReview
    when 'Case'
      Case
    else
      raise ArgumentError.new('Invalid case type parameter')
    end
  end
end
