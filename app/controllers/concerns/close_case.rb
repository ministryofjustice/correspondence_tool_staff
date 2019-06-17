module CloseCase
  extend ActiveSupport::Concern
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

  # Should be new
  def close
    # prepopulate date if it was entered by the KILO
    authorize @case, :can_close_case?

    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end
    set_permitted_events
  end

  # Should be edit
  def edit_closure
    authorize @case, :update_closure?

    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    @case = @case.decorate
    @team_collection = CaseTeamCollection.new(@case)
  end

  # Should be update
  def process_date_responded
    authorize @case, :can_close_case?

    @case = @case.decorate

    @case.prepare_for_respond
    if !@case.update process_date_responded_params(@correspondence_type_key)
      render :close
    else
      @team_collection = CaseTeamCollection.new(@case)
      @case.update(late_team_id: @case.responding_team.id)
      redirect_to closure_outcomes_case_path(@case)
    end
  end

  # Should be
  def closure_outcomes
    @case = @case.decorate # TODO: Is this required - see before_action hook!
    authorize @case, :can_close_case?

    if @case.ico?
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'responses')
    end
    @team_collection = CaseTeamCollection.new(@case)
  end

  # Should be create
  def process_closure
    authorize @case, :can_close_case?
    @case = @case.decorate
    close_params = process_closure_params(@case.type_abbreviation)
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
      render :closure_outcomes
    end
  end

  def respond_and_close
    authorize @case

    @case.date_responded = nil
    set_permitted_events
    render :close
  end

  def process_respond_and_close
    authorize @case, :respond_and_close?
    @case.prepare_for_close
    close_params = process_closure_params(@case.type_abbreviation)

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
      render :closure_outcomes
    end
  end

  # Should be update
  def update_closure
    authorize @case
    close_params = process_closure_params(@case.type_abbreviation)
    @case.prepare_for_close

    service = UpdateClosureService.new(@case, current_user, close_params)
    service.call
    if service.result == :ok
      set_permitted_events
      flash[:notice] = t('notices.closure_details_updated')
      redirect_to case_path(@case)
    else
      @case = @case.decorate
      render :edit_closure
    end
  end

  def respond
    authorize @case, :can_respond?
    set_correspondence_type(@case.type_abbreviation.downcase)
  end

  def confirm_respond
    authorize @case, :can_respond?
    params = respond_params(@correspondence_type_key)
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
end
