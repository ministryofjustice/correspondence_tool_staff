class StandardSetup
  include FactoryGirl::Syntax::Methods

  attr_reader :users, :cases, :teams

  def initialize

    @teams = {
       mangaging_team: find_or_create(:team_dacu),
       approving_team: find_or_create(:team_dacu_disclosure),
       responding_team: create(:responding_team),
       press_office: find_or_create(:team_press_office),
       private_office: find_or_create(:team_private_office)
    }


    @users = {
      manager: find_or_create(:disclosure_bmt_user),
      approver: find_or_create(:disclosure_specialist),
      other_approver: create(:approver),
      responder: create(:responder, responding_teams:[responding_team]),
      another_responder: create(:responder),
      press_officer: find_or_create(:press_officer),
      private_officer: find_or_create(:private_officer)
    }

    @cases = {
       std_unassigned_foi: create(:case),
       std_awresp_foi: create(:assigned_case, responding_team: @teams[:responding_team]),
       std_draft_foi: create(:accepted_case, responder: responder),
       std_awdis_foi: create(:case_with_response, responder: responder),
       std_responded_foi: create(:responded_case, responder: responder),
       std_closed_foi: create(:closed_case),
       trig_unassigned_foi: create(:case, :flagged_accepted, :dacu_disclosure, approver: approver),
       trig_awresp_foi: create(:assigned_case, :flagged_accepted, :dacu_disclosure, approver: approver, responding_team: @teams[:responding_team]),
       trig_draft_foi: create(:accepted_case, :flagged_accepted, :dacu_disclosure, responder: responder, approver: approver),
       trig_pdacu_foi: create(:pending_dacu_clearance_case, :flagged_accepted,  :dacu_disclosure, responder: responder, approver: approver),
       trig_awdis_foi: create(:case_with_response, :flagged_accepted, :dacu_disclosure, responder: responder, approver: approver),
       trig_responded_foi: create(:responded_case, :flagged_accepted, :dacu_disclosure, responder: responder, approver: approver),
       trig_closed_foi: create(:closed_case, :flagged_accepted, :dacu_disclosure, responder: responder, approver: approver),
       full_unassigned_foi: create(:case, :flagged_accepted, :press_office, responder: responder, approver: approver),
       full_awresp_foi: create(:assigned_case, :flagged_accepted, :press_office, approver: approver, responding_team: @teams[:responding_team]),
       full_draft_foi: create(:accepted_case, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_pdacu_foi: create(:pending_dacu_clearance_case, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_ppress_foi: create(:pending_press_clearance_case, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_pprivate_foi: create(:pending_private_clearance_case, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_awdis_foi: create(:case_with_response, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_responded_foi: create(:responded_case, :flagged_accepted, :press_office, responder: responder,  approver: approver),
       full_closed_foi: create(:closed_case, :flagged_accepted, :press_office),
    }
   end

   def method_missing(method_name, *args)
      if @users&.key?(method_name)
         @users[method_name]
      elsif @cases&.key?(method_name)
         @cases[method_name]
      elsif @teams&.key?(method_name)
        @teams[method_name]
      else
         super
      end
   end
end
