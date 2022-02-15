require './lib/translate_for_case'

class CasesController < ApplicationController
  include SetupCase
  include Closable

  before_action -> { set_case(params[:id]) }, only: [:edit, :update]

  before_action -> { set_decorated_case(params[:id]) }, only: [
    :show,
    :destroy,
    :confirm_destroy
  ]

  # Attributes used by sub-classes to set the current Case type for the request
  attr_reader :correspondence_type, :correspondence_type_key

  def show
    set_assignments

    if flash.key?(:query_id)
      SearchQuery.find(flash[:query_id])&.update_for_click(params[:pos].to_i)
    end

    if policy(@case).can_accept_or_reject_responder_assignment?
      redirect_to edit_case_assignment_path @case, @case.responder_assignment.id
    else
      authorize @case

      @correspondence_type_key = @case.type_abbreviation.downcase

      if flash.key?(:case_errors)
        flash[:case_errors][:message_text].each do |error|
          @case.errors.add(:message_text, error)
        end
      end

      set_permitted_events
      @accepted_now = params[:accepted_now]
      CasesUsersTransitionsTracker.sync_for_case_and_user(@case, current_user)

      render 'cases/show'
    end
  end

  def new
    permitted_correspondence_types
    authorize Case::Base, :can_add_case?

    render 'cases/select_type'
  end

  def create
    begin
      authorize case_type, :can_add_case?

      service = CaseCreateService.new(
        user: current_user,
        case_type: case_type,
        params: create_params
      )
      service.call
      @case = service.case

      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = service.message
        redirect_to new_case_assignment_path @case
      else
        @case = @case.decorate
        @case_types = @correspondence_type.sub_classes.map(&:to_s)
        @s3_direct_post = S3Uploader.for(@case, 'requests')
        render 'cases/new'
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:notice] = t('activerecord.errors.models.case.attributes.number.duplication')
      render 'cases/new'
    end
  end

  def edit
    set_correspondence_type(@case.type_abbreviation.downcase)

    authorize @case

    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    @s3_direct_post = S3Uploader.for(@case, 'requests')
    @case = @case.decorate
    render 'cases/edit'
  end

  def update
    @case = Case::Base.find(params[:id])
    authorize @case
    @case = @case.decorate
    preserve_step_state

    service = case_updater_service.new(current_user, @case, edit_params)
    service.call

    if service.result == :error
      @case_types = @correspondence_type.sub_classes.map(&:to_s)
      @s3_direct_post = S3Uploader.for(@case, 'requests')
      if service.error_message.present?
        flash[:alert] = service.error_message
      end
      render 'cases/edit' and return
    end

    if service.result == :ok
      flash[:notice] = t('cases.update.case_updated')
    elsif service.result == :no_changes
      flash[:alert] = "No changes were made"
    end

    set_permitted_events
    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    redirect_to case_path(@case)
  end


  def destroy
    authorize @case

    service = CaseDeletionService.new(
      current_user,
      @case,
      params.require(:case).permit(:reason_for_deletion)
    )
    service.call

    if service.result == :ok
      flash[:notice] = "You have deleted case #{@case.number}."
      redirect_to cases_path
    else
      @case.assign_attributes(params.require(:case).permit(:reason_for_deletion))
      render 'cases/confirm_destroy'
    end
  end

  def confirm_destroy
    authorize @case
  end

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias t4c translate_for_case


  protected

  def case_updater_service
    CaseUpdaterService
  end

  def case_type
    raise NotImplementedError
  end

  def create_params
    raise NotImplementedError
  end

  def edit_params
    raise NotImplementedError
  end


  # Catch exceptions as a result of a user not being authorised to perform an
  # action on a case. The default behaviour is to redirect them to '/' but here
  # we change that for certain actions where it makes sense (i.e. ones that
  # operate on a case) so that they redirect to the case show page (e.g.
  # approve, upload_responses).
  def user_not_authorized(exception)
    case exception.query
    when 'approve?',
         'can_add_attachment?',
         /^add_response_to_flagged_case/,
         'upload_responses?',
         'update_closure?'
      super(exception, case_path(@case))
    else
      super
    end
  end

  # This is how we should be building @permitted_correspondence_types, but it
  # is missing policies on CorrespondenceType
  # def permitted_correspondence_types
  #   @permitted_correspondence_types = current_user
  #                                       .permitted_correspondence_types
  #                                       .find_all do |type|
  #     Pundit.policy(current_user, type).can_add_case?
  #   end
  # end

  # See the commented-out method above, that should be our replacement. We just
  # assume that whatever managing team we're on will give us create
  # permissions, but that isn't strictly true, we should let the policy decide
  # that.
  def permitted_correspondence_types
    # Use the intermediary variable "types" to update
    # @permitted_correspondence_types so that it's changed as an atomic
    # operation ... we don't want to possibly allow SAR or ICO types to be
    # permitted at any point.
    @permitted_correspondence_types = []
    if current_user.managing_teams.present?
      @permitted_correspondence_types += correspondence_types_for_current_user
    elsif policy(Case::Base).can_manage_offender_sar?
      @permitted_correspondence_types << CorrespondenceType.offender_sar
      @permitted_correspondence_types << CorrespondenceType.offender_sar_complaint 
    end
  end


  def preserve_step_state
    # this method left intentionally blank
    # used by Steppable cases where validation fails on a particular step
    # e.g. Offender SAR
  end

  private

  def correspondence_types_for_current_user
    types = current_user.  
              managing_teams.  
              first.  
              correspondence_types.  
              menu_visible.
              order(:name).to_a

    add_sar_ir_to_permitted_types_if_sars_allowed(types)

    sar_ir_enabled = FeatureSet.sar_internal_review.enabled?

    types.delete(CorrespondenceType.sar_internal_review) unless sar_ir_enabled
    types
  end

  def add_sar_ir_to_permitted_types_if_sars_allowed(types)
    types.delete(CorrespondenceType.sar_internal_review)
    if types.include?(CorrespondenceType.sar)
      types << CorrespondenceType.sar_internal_review
    end
  end

end
