class TeamsController < ApplicationController

  before_action :set_team, only: [:business_areas_covered,
                                  :create_business_areas_covered,
                                  :destroy,
                                  :destroy_business_area,
                                  :edit,
                                  :move_to_directorate,
                                  :move_to_directorate_form,
                                  :join_teams,
                                  :join_teams_form,
                                  :join_target_team,
                                  :show,
                                  :update,
                                  :update_business_area,
                                  :update_business_area_form,
                                  :update_directorate,
                                  :move_to_business_group,
                                  :move_to_business_group_form,
                                  :update_business_group]

  before_action :set_areas, only: [:business_areas_covered,
                                   :create_business_areas_covered]
  
  before_action :default_params_to_include_sar_ir, only: [:update, 
                                                          :create] 

  def index
    @teams = policy_scope(Team).order(:name)
    @reports = ReportType.where(full_name: 'Business unit map')
    unless current_user.manager?
      render :teams_for_user
    else
      render :index
    end
  end

  def show
    authorize @team
    @reports = ReportType.where(full_name: 'Business unit map')
    @children = @team.children.order(:name)
    @active_users = @team.active_users
    @case_counts = UserActiveCaseCountService.new.case_counts_by_user(@active_users)
  end

  def edit
    authorize @team
    @action_copy = get_action_text(for_creation: false)
    @team_type = params[:team_type]
  end

  def update
    authorize @team

    if @team.update(team_params)
      redirect_to post_update_redirect_destination
    else
      render :edit
    end
  end

  def new
    authorize Team
    klass = get_class_from_team_type
    @team = klass.new
    @team.team_lead = ''
    @team.parent_id = params[:parent_id].to_i
    @team_type = params[:team_type]
    @action_copy = get_action_text(for_creation: true)
  end

  def create
    authorize Team.first
    klass = get_class_from_team_type
    @team = klass.new(new_team_params)
    @team.parent_id = nil if @team.is_a?(BusinessGroup)
    if @team.save
      if @team.is_a?(BusinessUnit)
        flash[:creating_team] = true
        redirect_to areas_covered_by_team_path(@team)
      else
        flash[:notice] = 'Team created'
        redirect_to params[:team_type] == 'bg' ? teams_path : team_path(@team.parent_id)
      end
    else
      @team_type = params[:team_type]
      render :new
    end
  end

  def business_areas_covered
    authorize @team
    @creating_team = flash[:creating_team]
    flash.keep :creating_team
  end

  def create_business_areas_covered
    authorize @team, :business_areas_covered?
    respond_to do |format|
      if @team.areas.create(business_areas_cover_params)
        format.js { render 'teams/business_areas/create'}
      end
    end
  end

  def destroy_business_area
    authorize @team, :business_areas_covered?

    area = @team.areas.find(params[:area_id])

    respond_to do |format|
      if area.destroy
        format.js { render 'teams/business_areas/destroy', locals: { area: area}}
      end
    end
  end

  def update_business_area_form
    authorize @team, :business_areas_covered?

    area = @team.areas.find(params[:area_id])

    respond_to do |format|
      format.js { render 'teams/business_areas/get_update_form', locals: { area: area}}
    end
  end

  def update_business_area
    authorize @team, :business_areas_covered?

    area = @team.areas.find(params[:area_id])

    if area.update(update_business_areas_cover_params)
      respond_to do | format |
        format.js { render 'teams/business_areas/update', locals: {areas: @team.areas}}
      end
    end
  end

  def destroy
    authorize @team
    service = TeamDeletionService.new(@team)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('teams.destroyed',
                        team_name: @team.original_team_name,
                        team_type: @team.pretty_type.downcase)
      redirect_to(set_destination(@team))
    else
      flash[:alert] = I18n.t('teams.error')
      redirect_to team_path(@team)
    end
  end

  def move_to_directorate
    authorize @team, :move?
    set_directorates if params[:business_group_id]
  end

  def move_to_business_group
    authorize @team, :move?
  end

  def move_to_business_group_form
    authorize @team, :move?
    @business_group = BusinessGroup.find(params[:business_group_id])
  end

  def move_to_directorate_form
    authorize @team, :move?
    @directorate = Directorate.find(params[:directorate_id])
  end

  def update_business_group
    authorize @team, :move?
    @business_group = BusinessGroup.find(params[:business_group_id])
    service = DirectorateMoveService.new(@team, @business_group)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('directorates.move.moved_successfully',
                        team_name: service.new_directorate.name,
                        destination_business_group_name: @business_group.name)
      redirect_to team_path(service.new_directorate)
    else
      flash[:alert] = I18n.t('directorates.move.error', reason: service.error_message)
      redirect_to team_path(@team)
    end
  end

  def update_directorate
    authorize @team, :move?
    @directorate = Directorate.find(params[:directorate_id])
    service = TeamMoveService.new(@team, @directorate)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('teams.move.moved_successfully',
                        team_name: service.new_team.name,
                        destination_directorate_name: @directorate.name)
      redirect_to team_path(service.new_team)
    else
      flash[:alert] = I18n.t('teams.error')
      redirect_to team_path(@team)
    end
  end

  def join_teams
    authorize @team, :join?
    set_directorates if params[:business_group_id]
    set_teams if params[:directorate_id]
  end

  def join_teams_form
    authorize @team, :join?
    @target_team = BusinessUnit.find(params[:target_team_id])
  end

  def join_target_team
    authorize @team, :join?
    @target_team = BusinessUnit.find(params[:target_team_id])
    service = TeamJoinService.new(@team, @target_team)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('teams.join.joined_successfully',
                        team_name: @team.original_team_name, target_team: @target_team.name)
      redirect_to team_path(service.target_team)
    else
      flash[:alert] = I18n.t('teams.error')
      redirect_to join_teams_form_team_path(@team)
    end
  end

  private

  def set_directorates
      @directorates = Directorate
        .where(parent_id: params[:business_group_id])
        .active
        .order(:name)
  end

  def set_teams
    @directorate = Directorate.find(params[:directorate_id])
    @business_units = @directorate.business_units.active
  end

  def team_params
    params.require(:team).permit(
        :name,
        :email,
        :team_lead,
        :role,
        correspondence_type_ids: []
    )
  end

  def new_team_params
    params.require(:team).permit(
        :name,
        :email,
        :team_lead,
        :parent_id,
        :role,
        correspondence_type_ids: []
    )
  end

  def business_areas_cover_params
    params.require(:team_property).permit(:value)
  end

  def destroy_business_areas_cover_params
    params.require(:team_property).permit(
        id: params[:area_id]
    )
  end

  def update_business_areas_cover_params
    params.require(:team_property).permit(
        :value,
        id: params[:area_id]
    )
  end

  def post_update_redirect_destination
    if @team.is_a?(BusinessUnit)
      areas_covered_by_team_path(@team)
    else
      flash[:notice] = 'Team details updated'
      @team.is_a?(BusinessGroup) ? teams_path : team_path(@team.parent_id)
    end
  end

  def get_class_from_team_type
    case params[:team_type]
    when 'bu'
      BusinessUnit
    when 'dir'
      Directorate
    when 'bg'
      BusinessGroup
    else
      raise ArgumentError.new('Invalid team type parameter')
    end
  end

  def set_team
    @team = Team.find(params[:id])
  end

  def set_areas
    @areas = @team.areas.order(id: :desc)
  end

  def get_action_text(for_creation: true)
    if @team.is_a?(BusinessUnit)
      if for_creation
        "Next - add areas covered"
      else
        "Next - edit areas covered"
      end
    else
      "Submit"
    end
  end

  def set_destination(team)
    team_is_bu = team.type == 'BusinessGroup'
    team_is_bu ? teams_path : team_path(team.parent_id)
  end

  def default_params_to_include_sar_ir
    # include access to SAR::InternalReviews if team has access to standard SARs
    return unless params[:team].fetch(:correspondence_type_ids, nil)
    sar_ir_ct_id = CorrespondenceType.sar_internal_review.id.to_s
    sar_ct_id = CorrespondenceType.sar.id.to_s
    if params[:team][:correspondence_type_ids].include?(sar_ct_id)
      params[:team][:correspondence_type_ids] << sar_ir_ct_id
    end
  end
end
