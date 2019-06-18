require './lib/translate_for_case'

class CasesController < ApplicationController
  include SetupCase

  before_action :set_case, only: [
    :closure_outcomes,
    :edit_closure,
    :process_date_responded,
    :update_closure
  ]

  before_action :set_decorated_case, only: [
    :close,
    :confirm_respond,
    :process_closure,
    :process_respond_and_close,
    :respond,
    :respond_and_close
  ]

  # Attributes used by sub-classes to set the current Case type for the request
  attr_reader :correspondence_type, :correspondence_type_key

  def show
    set_decorated_case(params[:id])
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

      render :show
    end
  end

  def new
    permitted_correspondence_types
    authorize Case::Base, :can_add_case?

    # Remnant from existing case creation journey hence mismatching template
    render :select_type
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
        render :new
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:notice] = t('activerecord.errors.models.case.attributes.number.duplication')
      render :new
    end
  end

  def edit
    set_case(params[:id])
    set_correspondence_type(@case.type_abbreviation.downcase)

    authorize @case

    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    @s3_direct_post = S3Uploader.for(@case, 'requests')
    @case = @case.decorate
    render :edit
  end

  def update
    #set_decorated_case(params[:id]) # TODO: Repeating case load!
    set_correspondence_type(params.fetch(:correspondence_type))
    @case = Case::Base.find(params[:id])
    authorize @case

    #case_params = edit_params(@correspondence_type_key)
    service = CaseUpdaterService.new(current_user, @case, edit_params)
    service.call

    if service.result == :error
      @case = @case.decorate
      # flash[:notice] = t('.case_error')
      render :edit and return
    end

    if service.result == :ok
      flash[:notice] = t('.case_updated')
    elsif service.result == :no_changes
      flash[:alert] = "No changes were made"
    end

    set_permitted_events
    @case = @case.decorate
    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    redirect_to case_path(@case)
  end

  def destroy
    set_decorated_case(params[:id])
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
      render :confirm_destroy
    end
  end

  def confirm_destroy
    set_decorated_case(params[:id])
    authorize @case
  end

  # All existing partials are in /views/cases
  def self.controller_path
    'cases'
  end


  # @note: Case Closure and Respond methods require refactoring as the behaviours
  # are currently undocumented and may require further investigation/checks
  # as not all

  # Prepopulate date if it was entered by the KILO
  def close
    authorize @case, :can_close_case?

    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end

    set_permitted_events
    render 'cases/closures/close'
  end

  def edit_closure
    authorize @case, :update_closure?

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @case = @case.decorate
    @team_collection = CaseTeamCollection.new(@case)

    render 'cases/closures/edit_closure'
  end

  def closure_outcomes
    @case = @case.decorate # @todo: Required? - See before_action hook!
    authorize @case, :can_close_case?

    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end
    @team_collection = CaseTeamCollection.new(@case)

    render 'cases/closures/closure_outcomes'
  end

  def respond_and_close
    authorize @case

    @case.date_responded = nil
    set_permitted_events
    render 'cases/closures/close'
  end

  def respond
    authorize @case, :can_respond?
    set_correspondence_type(@case.type_abbreviation.downcase)
    render 'cases/closures/respond'
  end

  def process_date_responded
    authorize @case, :can_close_case?

    @case = @case.decorate
    @case.prepare_for_respond

    if !@case.update process_date_responded_params
      render render 'cases/closures/close'
    else
      @team_collection = CaseTeamCollection.new(@case)
      @case.update(late_team_id: @case.responding_team.id)
      redirect_to closure_outcomes_case_path(@case)
    end
  end

  def process_closure
    authorize @case, :can_close_case?

    @case = @case.decorate
    close_params = process_closure_params
    service = CaseClosureService.new(@case, current_user, close_params)
    service.call

    if service.result == :ok
      set_permitted_events
      flash[:notice] = service.flash_message
      redirect_to case_path(@case)
    else
      set_permitted_events
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
      @team_collection = CaseTeamCollection.new(@case)
      render render 'cases/closures/closure_outcomes'
    end
  end

  def process_respond_and_close
    authorize @case, :respond_and_close?

    @case.prepare_for_close
    close_params = process_closure_params

    if @case.update(close_params)
      @case.respond_and_close(current_user)
      set_permitted_events
      @close_flash_message = t('notices.case_closed')
      if @permitted_events.include?(:update_closure)
        flash[:notice] = "#{@close_flash_message}. #{ get_edit_close_link }".html_safe
      else
        flash[:notice] = @close_flash_message
      end
      redirect_to case_path(@case)
    else
      set_permitted_events
      @team_collection = CaseTeamCollection.new(@case)
      render render 'cases/closures/closure_outcomes'
    end
  end

  def update_closure
    authorize @case

    close_params = process_closure_params
    @case.prepare_for_close

    service = UpdateClosureService.new(@case, current_user, close_params)
    service.call

    if service.result == :ok
      set_permitted_events
      flash[:notice] = t('notices.closure_details_updated')
      redirect_to case_path(@case)
    else
      @case = @case.decorate
      render 'cases/closures/edit_closure'
    end
  end

  def confirm_respond
    authorize @case, :can_respond?

    params = respond_params
    service = MarkResponseAsSentService.new(@case, current_user, params)
    service.call

    case service.result
    when :ok
      flash[:notice] = t('.success')
      redirect_to case_path(@case)
    when :late
      @team_collection = CaseTeamCollection.new(@case)
      render '/cases/ico/late_team'
    when :error
      set_correspondence_type(@case.type_abbreviation.downcase)
      render :respond
    else
      raise 'unexpected result from MarkResponseAsSentService'
    end
  end


  protected

  def case_type
    raise NotImplementedError
  end

  def create_params
    raise NotImplementedError
  end

  def edit_params
    raise NotImplementedError
  end

  def process_closure_params
    raise NotImplementedError
  end

  def respond_params
    raise NotImplementedError
  end

  def process_date_responded_params
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
    types = current_user.managing_teams.first.correspondence_types.menu_visible.order(:name).to_a
    types.delete(CorrespondenceType.sar) unless FeatureSet.sars.enabled?
    types.delete(CorrespondenceType.ico) unless FeatureSet.ico.enabled?
    types << CorrespondenceType.offender_sar if FeatureSet.offender_sars.enabled?

    @permitted_correspondence_types = types
  end

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias t4c translate_for_case
end
