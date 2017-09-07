class Admin::CasesController < ApplicationController
  before_action :authorize_admin

  def create
    @case = Case.new(case_params)
    @selected_state = params[:target_state]
    if @case.valid?
      options = {}
      options[:flag_for_disclosure] =
        params[:case][:flagged_for_disclosure_specialist_clearance] == '1'
      options[:flag_for_pr] =
        params[:case][:flagged_for_disclosure_specialist_clearance] == '1'
      options[:flag_for_disclosure] =
        params[:case][:flagged_for_disclosure_specialist_clearance] == '1'

      case_creator = CTS::Cases::Create.new(nil)
      case_creator.call([@selected_state], options)
      redirect_to(admin_cases_path)
    else
      @case.responding_team = BusinessUnit.find(
        params[:case][:responding_team_attributes][:id]
      )

      if params[:case][:flagged_for_disclosure_specialist_clearance] == '1'
        @case.approving_teams << BusinessUnit.dacu_disclosure
      end
      if params[:case][:flagged_for_press_office_clearance] == '1'
        @case.approving_teams << BusinessUnit.press_office
      end
      if params[:case][:flagged_for_private_office_clearance] == '1'
        @case.approving_teams << BusinessUnit.private_office
      end

      @target_states = available_target_states
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
      render :new
    end
  end

  def index
    @cases = Case.all.order(id: :desc).page(params[:page]).decorate
  end

  def new
    case_creator = CTS::Cases::Create.new(nil)
    @case = case_creator.new_case
    @case.responding_team = BusinessUnit.responding.sample
    @case.flag_for_disclosure_specialists = 'no'
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
    render :new
  end

  private

  def authorize_admin
    authorize Case.new, :user_is_admin?
  end

  def available_target_states
    CTS::Cases::Create::CASE_JOURNEYS.values.flatten.uniq.sort
  end

  def case_params
    params.require(:case).permit(
      :requester_type,
      :name,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: [],
    ).merge(category_id: Category.find_by(abbreviation: 'FOI').id)
  end
end
