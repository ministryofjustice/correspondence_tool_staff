# @note: Case Closure and Respond methods require refactoring as per
# other case behaviours
module Closable
  extend ActiveSupport::Concern
  include SetupCase

  included do
    before_action -> { set_case(params[:id]) }, only: [
      :closure_outcomes,
      :edit_closure,
      :process_date_responded,
      :update_closure
    ]

    before_action -> { set_decorated_case(params[:id]) }, only: [
      :close,
      :confirm_respond,
      :process_closure,
      :process_respond_and_close,
      :respond,
      :respond_and_close
    ]
  end


  # Pre-populate date if it was entered by the KILO
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
      render 'cases/closures/close'
    else
      @team_collection = CaseTeamCollection.new(@case)
      @case.update(late_team_id: @case.responding_team.id)
      redirect_to polymorphic_path(@case, action: :closure_outcomes)
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
      render 'cases/closures/closure_outcomes'
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
        flash[:notice] = "#{@close_flash_message}. #{get_edit_close_link}".html_safe
      else
        flash[:notice] = @close_flash_message
      end
      redirect_to case_path(@case)
    else
      set_permitted_events
      @team_collection = CaseTeamCollection.new(@case)
      render 'cases/closures/closure_outcomes'
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
      render 'cases/ico/late_team'
    when :error
      set_correspondence_type(@case.type_abbreviation.downcase)
      render 'cases/closures/respond'
    else
      raise 'unexpected result from MarkResponseAsSentService'
    end
  end


  protected

  def process_closure_params
    raise NotImplementedError
  end

  def respond_params
    raise NotImplementedError
  end

  def process_date_responded_params
    raise NotImplementedError
  end


  private

  def get_edit_close_link
    view_context.link_to(
      "Edit case closure details",
      polymorphic_path(@case, action: :edit_closure),
      { class: "undo-take-on-link" }
    )
  end
end
