class ReportTypePolicy < ApplicationPolicy
  attr_reader :user, :report_type

  def initialize(user, report_type)
    @report_type = report_type
    super(user, report_type)
  end

  # PolicyScopes
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user  = user
      @scope = scope
    end

    # Solve the scope by go through each allowed correspondence_type the user being allowed to see
    def resolve
      scopes = []
      scopes << @scope.where(sar: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.overturned_sar)
      scopes << @scope.where(sar: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.sar)
      scopes << @scope.where(foi: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.foi)
      scopes << @scope.where(foi: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.overturned_foi)
      scopes << @scope.where(offender_sar: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.offender_sar)
      scopes << @scope.where(offender_sar_complaint: true) if @user.permitted_correspondence_types.include?(CorrespondenceType.offender_sar_complaint)
      scopes.reduce { |memo, scope| memo.or(scope) }
    end
  end

  def can_run?
    clear_failed_checks
  end
end
