require 'cts/cases/create'
require 'cts/cases/constants'


class Admin::CasesController < ApplicationController
  before_action :authorize_admin

  def create
    prepare_flagged_options_for_creation(params)
    case_creator = CTS::Cases::Create.new(Rails.logger, params[:case])
    @case = case_creator.new_case
    @selected_state = params[:case][:target_state]
    if @case.valid?
      case_creator.call([@selected_state], @case)
      flash[:notice] = "Case created: #{@case.number}"
      redirect_to(admin_cases_path)
    else
      @case.responding_team = BusinessUnit.find(
        params[:case][:responding_team]
      )
      prepare_flagged_options_for_displaying
      @target_states = available_target_states
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
      render :new
    end
  end

  def index
    @cases = Case::Base.all.order(id: :desc).page(params[:page]).decorate
  end

  def new
    if params[:correspondence_type].present?
      prepare_new_case
    else
    prepare_select_type
    end
  end

  def prepare_new_case
    @correspondence_type_abbreviation = params[:correspondence_type]
      case_class = correspondence_types_map[@correspondence_type_abbreviation.to_sym].first
      @case = case_class.new

    case_creator = CTS::Cases::Create.new(Rails.logger, case_model: Case::Base, type: some_method  )
    @case = case_creator.new_case
    @case.responding_team = BusinessUnit.responding.sample
    @case.flag_for_disclosure_specialists = 'no'
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')

    @case.subject_type = 'member_of_the_public'
    @case.third_party = false
    @case.subject_full_name = name
    render :new
  end

  def some_method
    if @correspondence_type_abbreviation == 'sar'
      'Case::SAR'
    else
      'Case::FOI::Standard'
    end
  end

  private

  def prepare_select_type
    permitted_correspondence_types
    render :select_type
  end

  def permitted_correspondence_types
    @permitted_correspondence_types = [CorrespondenceType.foi, CorrespondenceType.sar]
  end

  def authorize_admin
    authorize Case::Base, :user_is_admin?
  end

  def available_target_states
    CTS::Cases::Constants::CASE_JOURNEYS[@correspondence_type_abbreviation.to_sym].values.flatten.uniq.sort
  end

  def case_params
    params.require(:case).permit(
      :type,
      :requester_type,
      :name,
      :subject_full_name,
      :third_party,
      :subject_type,
      :postal_address,
      :email,
      :subject,
      :message,
      :received_date_dd, :received_date_mm, :received_date_yyyy,
      :delivery_method,
      :flag_for_disclosure_specialists,
      uploaded_request_files: [],
    )
  end

  def param_flag_for_ds?
    params[:case][:flagged_for_disclosure_specialist_clearance] == '1'
  end

  def param_flag_for_press?
    params[:case][:flagged_for_press_office_clearance] == '1'
  end

  def param_flag_for_private?
    params[:case][:flagged_for_private_office_clearance] == '1'
  end

  def gather_teams_for_flagging
    teams_for_flagging = []
    teams_for_flagging << 'disclosure' if param_flag_for_ds?
    teams_for_flagging << 'press' if param_flag_for_press?
    teams_for_flagging << 'private' if param_flag_for_private?
    teams_for_flagging
  end

  def prepare_flagged_options_for_creation(params)
    if param_flag_for_ds? && !param_flag_for_press? && !param_flag_for_private?
      params[:case][:flag_for_disclosure] = true
    else
      params[:case][:flag_for_team] = gather_teams_for_flagging.join(',')
    end
  end

  def prepare_flagged_options_for_displaying
    @case.approving_teams << BusinessUnit.dacu_disclosure if param_flag_for_ds?
    @case.approving_teams << BusinessUnit.press_office if param_flag_for_press?
    @case.approving_teams << BusinessUnit.private_office if param_flag_for_private?
  end

  def correspondence_types_map
    @correspondence_types_map ||= {
      foi: [Case::FOI::Standard,
            Case::FOI::TimelinessReview,
            Case::FOI::ComplianceReview],
      sar: [Case::SAR],
    }.with_indifferent_access
  end
end
