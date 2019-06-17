module Cases
  class ClosuresController < ApplicationController
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







    private

    def process_closure_params(correspondence_type)
      case correspondence_type
      when 'FOI', 'OVERTURNED_FOI' then process_foi_closure_params
      when 'SAR', 'OVERTURNED_SAR' then process_sar_closure_params
      when 'ICO' then process_ico_closure_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def respond_params(correspondence_type)
      case correspondence_type
      when 'foi' then respond_foi_params
      when 'sar' then respond_sar_params
      when 'ico' then respond_ico_params
      when 'overturned_foi', 'overturned_sar' then respond_overturned_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def process_date_responded_params(correspondence_type)
      case correspondence_type
      when 'foi' then respond_foi_params
      when 'sar' then respond_sar_params
      when 'ico' then ico_close_date_responded_params
      when 'overturned_foi', 'overturned_sar' then respond_overturned_params
      else raise "Unknown case type '#{correspondence_type}'"
      end
    end

    def get_edit_close_link
      edit_close_link = edit_closure_case_path(@case)
      view_context.link_to "Edit case closure details",
                           edit_close_link,
                           { class: "undo-take-on-link" }
    end




    # PARAMETERS
    # def process_foi_closure_params
    #   closure_params = params.require(:foi).permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #     :outcome_abbreviation,
    #     :appeal_outcome_name,
    #     :refusal_reason_abbreviation,
    #     :info_held_status_abbreviation,
    #     :late_team_id,
    #     exemption_ids: [],
    #   )
    #
    #   info_held_status = closure_params[:info_held_status_abbreviation]
    #   outcome          = closure_params[:outcome_abbreviation]
    #   refusal_reason   = closure_params[:refusal_reason_abbreviation]
    #
    #   unless ClosedCaseValidator.outcome_required?(info_held_status: info_held_status)
    #     closure_params.merge!(outcome_id: nil)
    #     closure_params.delete(:outcome_abbreviation)
    #   end
    #
    #   unless ClosedCaseValidator.refusal_reason_required?(info_held_status: info_held_status)
    #     closure_params.merge!(refusal_reason_id: nil)
    #     closure_params.delete(:refusal_reason_abbreviation)
    #   end
    #
    #   unless ClosedCaseValidator.exemption_required?(info_held_status: info_held_status,
    #     outcome: outcome,
    #     refusal_reason: refusal_reason)
    #     closure_params.merge!(exemption_ids: [])
    #   end
    #
    #   closure_params
    # end
    # def process_sar_closure_params
    #   params.require(:sar).permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #     :late_team_id,
    #   ).merge(refusal_reason_abbreviation: missing_info_to_tmm)
    # end
    # def process_ico_closure_params
    #   params.require(:ico).permit(
    #     :date_ico_decision_received_dd,
    #     :date_ico_decision_received_mm,
    #     :date_ico_decision_received_yyyy,
    #     :ico_decision_comment,
    #     :ico_decision,
    #     :late_team_id,
    #     uploaded_ico_decision_files: [],
    #   )
    # end
    # def respond_foi_params
    #   params.require(:foi).permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #   )
    # end
    # def respond_sar_params
    #   params.require(:sar).permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #   )
    # end
    # def respond_ico_params
    #   params.require(:ico).permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #   )
    # end
    # def respond_overturned_params
    #   params.require("case_#{@correspondence_type_key}").permit(
    #     :date_responded_dd,
    #     :date_responded_mm,
    #     :date_responded_yyyy,
    #   )
    # end
  end
end
