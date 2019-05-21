#rubocop:disable Metrics/ClassLength
require './lib/translate_for_case'

class Cases::BaseController < ApplicationController
  before_action :set_case, only: [:edit]
  before_action :set_assignments, only: [:show]

  # As per the Draper documentation, we really shouldn't be decorating @case at
  # the beginning of controller actions (see:
  # https://github.com/drapergem/draper#when-to-decorate-objects) as we do
  # here. Unfortunately we have a good bit of code that already relies on @case
  # being a decorator so instead of changing each of these actions let's
  # relegate them to a deprecated 'set_decorated_case' and change `set_case` to
  # not decorate @case. Also, as "case" is a reserved word in Ruby, the
  # suggestion in the Draper documentation isn't the best idea. So for an
  # action to move from using set_decorated_case to set_case it will have to
  # re-assign @case to be decorated, e.g.:
  #
  #   @case = @case.decorate
  #
  # or, this could be done in a new after_action block.
  before_action :set_decorated_case, only: [
    :confirm_destroy,
    :destroy,
    :show,
    :update,
  ]


  def index
    @cases = CaseFinderService.new(current_user)
      .for_params(request.params)
      .scope
      .page(params[:page])
      .decorate
    @current_tab_name = 'all_cases'
    @can_add_case = policy(Case::Base).can_add_case?
  end

  def show
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

    if params[:correspondence_type].present?
      set_correspondence_type(params[:correspondence_type])
      prepare_new_case
      # TODO: Redirect to appropriate new here
      render :new
    else
      # set_creatable_correspondence_types
      authorize Case::Base, :can_add_case?
      render :select_type
    end
  end

  def create
    begin
      set_correspondence_type(params.fetch(:correspondence_type))
      service = CaseCreateService.new(
        current_user,
        @correspondence_type_key,
        params
      )

      authorize service.case_class, :can_add_case?

      service.call
      @case = service.case

      case service.result
      when :assign_responder
        flash[:creating_case] = true
        flash[:notice] = service.flash_notice
        redirect_to new_case_assignment_path @case
      else
        @case = @case.decorate
        @case_types = @correspondence_type.sub_classes.map(&:to_s)
        @s3_direct_post = s3_uploader_for @case, 'requests'
        render :new
      end
    rescue ActiveRecord::RecordNotUnique
      flash.now[:notice] = t('activerecord.errors.models.case.attributes.number.duplication')
      render :new
    end
  end

  def edit
    set_correspondence_type(@case.type_abbreviation.downcase)
    authorize @case

    @case_transitions = @case.transitions.case_history.order(id: :desc).decorate
    @s3_direct_post = s3_uploader_for(@case, 'requests')
    @case = @case.decorate
    render :edit
  end

  def update
    set_correspondence_type(params.fetch(:correspondence_type))
    @case = Case::Base.find(params[:id])
    authorize @case

    case_params = edit_params(@correspondence_type_key)
    service = CaseUpdaterService.new(current_user, @case, case_params)
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
    authorize @case
  end

  # All existing partials are in /views/cases
  def self.controller_path
    'cases'
  end


  protected

  def set_url
    @action_url = request.env['PATH_INFO']
  end

  def set_permitted_events
    @permitted_events = @case.state_machine.permitted_events(current_user.id)
    @permitted_events ||= []
    @filtered_permitted_events = @permitted_events - [:extend_for_pit, :request_further_clearance, :link_a_case, :remove_linked_case]
  end

  def set_decorated_case
    set_case
    @case = @case.decorate
    @case_transitions = @case_transitions.decorate
  end

  def set_case
    @case = Case::Base
      .includes(
        :message_transitions,
        transitions: [:acting_user, :acting_team, :target_team],
        assignments: [:team],
        approver_assignments: [:user]
      )
      .find(params[:id])

    @case_transitions = @case.transitions.case_history.order(id: :desc)
    @correspondence_type_key = @case.type_abbreviation.downcase
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

  def s3_uploader_for(kase, upload_type)
    S3Uploader.s3_direct_post_for_case(kase, upload_type)
  end

  def set_correspondence_type(type)
    @correspondence_type = CorrespondenceType.find_by_abbreviation(type.upcase)
    @correspondence_type_key = type
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
    @permitted_correspondence_types = types
  end

  def translate_for_case(*args, **options)
    options[:translator] ||= public_method(:t)
    TranslateForCase.translate(*args, **options)
  end
  alias t4c translate_for_case


  private

  def set_assignments
    @assignments = []

    if @case.responding_team.in? current_user.responding_teams
      @assignments << @case.responder_assignment
    end

    if current_user.approving_team.in? @case.approving_teams
      @assignments << @case.assignments.for_team(current_user.approving_team.id).last
    end
  end

  def prepare_new_case
    valid_type = validate_correspondence_type(params[:correspondence_type].upcase)

    if valid_type == :ok
      set_correspondence_type(params[:correspondence_type])
      default_subclass = @correspondence_type.sub_classes.first

      # Check user's authorisation
      #
      # We don't know what kind of case type (FOI Standard, IR Timeliness, etc)
      # they want to create yet, but we need to authenticate them against some
      # kind of case class, so pick the first subclass available to them. This
      # could be improved by making case_subclasses a list of the case types
      # they are permitted to create, and when that list is empty rejecting
      # authorisation.
      authorize default_subclass, :can_add_case?

      @case = default_subclass.new.decorate
      @case_types = @correspondence_type.sub_classes.map(&:to_s)
      @s3_direct_post = s3_uploader_for(@case, 'requests')
    else
      flash.alert =
        helpers.t "cases.new.correspondence_type_errors.#{validation_result}",
                  type: @correspondence_type_key
      redirect_to new_case_path
    end
  end

  def validate_correspondence_type(ct_abbr)
    ct_exists    = ct_abbr.in?(CorrespondenceType.pluck(:abbreviation))
    ct_permitted = ct_abbr.in?(@permitted_correspondence_types.map(&:abbreviation))

    if ct_exists && ct_permitted
      :ok
    elsif !ct_exists
      :unknown
    else
      :not_authorised
    end
  end

  def edit_params(correspondence_type)
    case correspondence_type
    when 'foi' then edit_foi_params
    when 'ico' then edit_ico_params
    when 'sar' then edit_sar_params
    end
  end
end
#rubocop:enable Metrics/ClassLength
