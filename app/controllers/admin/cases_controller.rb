require 'cts/cases/create'
require 'cts/cases/constants'

class Admin::CasesController < AdminController

  before_action :set_correspondence_type,
                only: [
                  :create,
                  :new,
                ]

  def create
    @correspondence_type_key = params.fetch(:correspondence_type).downcase
    case_params = params[case_and_type]
    case_params[:creator] = current_user

    prepare_flagged_options_for_creation(params)
    case_creator = CTS::Cases::Create.new(Rails.logger, case_params)

    @case = case_creator.new_case
    @selected_state = case_params[:target_state]
    (result, _case) = case_creator.call(@selected_state, @case)
    if result == :ok
      flash[:notice] = "Case created: #{@case.number}"
      redirect_to(admin_cases_path)
    else
      @case.responding_team = BusinessUnit.find(
        case_params[:responding_team]
      )
      prepare_flagged_options_for_displaying
      @target_states = available_target_states
      @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
      render :new
    end
  end

  def index
    @dates = { }
    5.times do |n|
      date = n.business_days.ago.to_date
      @dates[date] = count_cases_created_on(date)
    end
    @cases = Case::Base.all.order(id: :desc).page(params[:page]).decorate
  end

  def new
    if params[:correspondence_type].present?
      @correspondence_type_key = params[:correspondence_type]
      prepare_new_case(creator: current_user)
    else
      select_type
    end
  end

  private

  def count_cases_created_on(date)
    Case::Base.where(created_at:  date.beginning_of_day..date.end_of_day).count
  end

  def select_type
    permitted_correspondence_types

    render :select_type
  end

  def prepare_new_case(creator:)
    case_creator = CTS::Cases::Create.new(
      Rails.logger,
      type: class_for_case,
      creator: creator
    )

    @case = case_creator.new_case
    @case.responding_team = BusinessUnit
                              .responding
                              .responding_for_correspondence_type(correspondence_type_for_case)
                              .active
                              .sample
    @case.flag_for_disclosure_specialists = 'no'
    @target_states = available_target_states
    @selected_state = 'drafting'
    @s3_direct_post = S3Uploader.s3_direct_post_for_case(@case, 'requests')
  end

  def permitted_correspondence_types
    @permitted_correspondence_types = [
      CorrespondenceType.foi,
      CorrespondenceType.sar,
      CorrespondenceType.ico,
      CorrespondenceType.overturned_sar,
      CorrespondenceType.overturned_foi, 
    ]
  end

  def correspondence_type_for_case
    correspondence_types ={
      'foi'             => CorrespondenceType.foi,
      'sar'             => CorrespondenceType.sar,
      'ico'             => CorrespondenceType.ico,
      'overturned_foi'  => CorrespondenceType.foi,
      'overturned_sar'  => CorrespondenceType.sar, 
    }
    correspondence_types[@correspondence_type_key]
  end

  def class_for_case
    case_classes = {
      'foi'              => 'Case::FOI::Standard',
      'sar'              => 'Case::SAR::Standard',
      'ico'              => 'Case::ICO::FOI',
      'overturned_foi'   => 'Case::OverturnedICO::FOI',
      'overturned_sar'   => 'Case::OverturnedICO::SAR',
    }
    case_classes[@correspondence_type_key]
  end

  def available_target_states
    CTS::Cases::Constants::CASE_JOURNEYS[@case.class.state_machine_name.to_sym].values.flatten.uniq.sort
  end

  def param_flag_for_ds?
    params[case_and_type][:flagged_for_disclosure_specialist_clearance] == '1' ||
        case_and_type == :case_ico
  end

  def param_flag_for_press?
    params[case_and_type][:flagged_for_press_office_clearance] == '1'
  end

  def param_flag_for_private?
    params[case_and_type][:flagged_for_private_office_clearance] == '1'
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
      params[case_and_type][:flag_for_disclosure] = true
    else
      params[case_and_type][:flag_for_team] = gather_teams_for_flagging.join(',')
    end
  end

  def prepare_flagged_options_for_displaying
    @case.approving_teams << BusinessUnit.dacu_disclosure if param_flag_for_ds?
    @case.approving_teams << BusinessUnit.press_office if param_flag_for_press?
    @case.approving_teams << BusinessUnit.private_office if param_flag_for_private?
  end

  def case_and_type
    "case_#{@correspondence_type_key}".to_sym
  end

  def set_correspondence_type
    if params[:correspondence_type].present?
      @correspondence_type = CorrespondenceType.find_by(
        abbreviation: params[:correspondence_type].upcase
      )
    end
  end
end
