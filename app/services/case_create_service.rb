class CaseCreateService
  attr_reader :case, :result, :message
  attr_reader :case_type # Used for tests

  def initialize(user:, case_type:, params:)
    @user = user
    @case_type = case_type
    @params = params

    @result, @case, @message = nil
  end

  def call
    @case = @case_type.new(@params.to_unsafe_h.merge(creator: @user).except!('type'))

    if @case.invalid? || @result == :error
      @result = :error
    elsif flagged_for_disclosure_specialists_mismatch?
      set_flagged_for_disclosure_errors
      @result = :error
    else
      flag_for_disclosure_if_required
      overturned_ico_post_creation_processing if @case.overturned_ico?
      @result = :assign_responder
    end

    @result != :error
  end

  private

  # TODO: Move to relevant controller
  def overturned_ico_post_creation_processing
    @case.link_related_cases
  end

  def flagged_for_disclosure_specialists_mismatch?
    @params[:flag_for_disclosure_specialists].blank? &&
      @case.requires_flag_for_disclosure_specialists?
  end

  def set_flagged_for_disclosure_errors
    @case.valid?
    @case.errors.add(:flag_for_disclosure_specialists, :blank)
  end

  def flag_for_disclosure_if_required
    @case.save!
    @message = "#{@case.decorate.pretty_type} case created<br/>Case number: #{@case.number}".html_safe

    if @params[:flag_for_disclosure_specialists] == 'yes'
      CaseFlagForClearanceService.new(
        user: @user,
        kase: @case,
        team: BusinessUnit.dacu_disclosure
      ).call
    end
    flag_for_disclosure if @case.is_a?(Case::ICO::Base)
  end

  def flag_for_disclosure
    service = CaseFlagForClearanceService.new(
      user: @user,
      kase: @case,
      team: BusinessUnit.dacu_disclosure
    )
    result = service.call

    raise "Unable to Flag ICO case for disclosure: #{result}" unless result == :ok
  end
end
