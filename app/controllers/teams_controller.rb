class TeamsController < ApplicationController

  before_action :set_team, only: [:business_areas_covered,
                                  :create_business_areas_covered,
                                  :show,
                                  :edit,
                                  :destroy_business_area,
                                  :update_business_area,
                                  :update_business_area_form,
                                  :update]

  before_action :set_areas, only: [:business_areas_covered,
                                   :create_business_areas_covered]

  def index
    @teams = policy_scope(Team)
    unless current_user.manager?
      render :teams_for_user
    else
      render :index
    end
  end

  def show
    authorize @team
    @children = @team.children
  end

  def edit
    authorize @team
    @action_copy = get_action_text(for_creation: false)
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
        format.js { render 'teams/business_areas/destroy', locals: { area:area}}
      end
    end
  end

  def update_business_area_form
    authorize @team, :business_areas_covered?

    area = @team.areas.find(params[:area_id])

    respond_to do |format|
      format.js { render 'teams/business_areas/get_update_form', locals: { area:area}}
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
    authorize @user
    team = Team.find(params[:id])
    service = TeamDeletionService.new(params)
    service.call
    case service.result
    when :ok
      flash[:notice] = I18n.t('teams.destroyed')
      redirect_to(set_destination(team))
    else
      flash[:alert] = I18n.t('teams.error',
        team_type: team.pretty_type,
        child_type: team.child_type)
      redirect_to(team_path)
    end
  end

  private

  def team_params
    params.require(:team).permit(
        :name,
        :email,
        :team_lead,
        :role,
        category_ids: []
    )
  end

  def new_team_params
    params.require(:team).permit(
        :name,
        :email,
        :team_lead,
        :parent_id,
        :role,
        category_ids: []
    )
  end

  def business_areas_cover_params
    params.require(:team_property).permit(
        :value
    )
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

    if current_user.manager?
      if @team.is_a?(BusinessUnit)
        areas_covered_by_team_path(@team)
      else
        flash[:notice] = 'Team details updated'
        params[:team_type] == 'bg' ? teams_path : team_path(@team.parent_id)
      end
    else
      if @team.is_a?(BusinessUnit)
        areas_covered_by_team_path(@team)
      else
        flash[:notice] = 'Team details updated'
        team_path(@team.id)
      end
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
    if team.type == 'BusinessGroup'
      teams_path
    else
      team_path(team.parent_id)
    end
  end

end
