class StandardSetup
  include FactoryGirl::Syntax::Methods

  attr_reader :cases, :user_teams
  # rubocop:disable Metrics/MethodLength

  def initialize
    @teams = {
       disclosure_bmt_team:       find_or_create(:team_dacu),
       disclosure_team:           find_or_create(:team_dacu_disclosure),
       responding_team:           create(:responding_team),
       press_office_team:         find_or_create(:team_press_office),
       private_office_team:       find_or_create(:team_private_office),
       another_approving_team:    create(:approving_team)
    }


    @users = {
      disclosure_bmt_user:                  find_or_create(:disclosure_bmt_user),
      disclosure_specialist_user:           find_or_create(:disclosure_specialist),
      disclosure_specialist_coworker_user:  create(:disclosure_specialist, approving_team: disclosure_team),
      another_disclosure_specialist_user:   create(:disclosure_specialist, approving_team: another_approving_team),
      responder_user:                       create(:responder, responding_teams:[responding_team]),
      another_responder_in_same_team_user:  create(:responder, responding_teams:[responding_team]),
      another_responder_in_diff_team_user:  create(:responder),
      press_officer_user:                   find_or_create(:press_officer),
      private_officer_user:                 find_or_create(:private_officer)
    }

    @user_teams = {
        disclosure_bmt:                   [ disclosure_bmt_user, disclosure_bmt_team ],
        disclosure_specialist:            [ disclosure_specialist_user, disclosure_team ],
        disclosure_specialist_coworker:   [ disclosure_specialist_coworker_user, disclosure_team],
        another_disclosure_specialist:    [ another_disclosure_specialist_user, another_approving_team ],
        responder:                        [ responder_user, responding_team ],
        another_responder_in_same_team:   [ another_responder_in_same_team_user, responding_team ],
        another_responder_in_diff_team:   [ another_responder_in_diff_team_user, another_responder_in_diff_team_user.responding_teams.first ],
        press_officer:                    [ press_officer_user, press_office_team ],
        private_officer:                  [ private_officer_user, private_office_team ]
    }

    # cases are named <workflow>_<state>_<other_info> where:
    #
    # * workflow:
    #   * std - standard workflow
    #   * trig - trigger workflow
    #   * full = full_approval workflow
    #
    # * state
    #   * unassigned - unassigned
    #   * awdis       - awaiting_dispatch
    #   * awresp      - awaiting_responder
    #   * closed      - closed
    #   * draft       - drafting
    #   * pdacu       - pending_dacu_clearance
    #   * ppress      - pending_press_office_clearance
    #   * pprivate    - pending_private_office_clerance
    #   * responded   - responded
    #
    @cases = {
       std_unassigned_foi:        create(:case),
       std_awresp_foi:            create(:assigned_case,
                                          responding_team: @teams[:responding_team]),
       std_draft_foi:             create(:accepted_case,
                                          responder: responder_user),
       std_awdis_foi:             create(:case_with_response,
                                          responder: responder_user),
       std_responded_foi:         create(:responded_case,
                                          responder: responder_user),
       std_closed_foi:            create(:closed_case),
       trig_unassigned_foi_accepted:       create(:case,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          approver: disclosure_specialist_user),
       trig_unassigned_foi:       create(:case,
                                         :flagged,
                                         :dacu_disclosure),
       trig_awresp_foi_accepted:  create(:assigned_case,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          approver: disclosure_specialist_user,
                                          responding_team: @teams[:responding_team]),
       trig_awresp_foi:           create(:assigned_case,
                                         :flagged,
                                         :dacu_disclosure,
                                         responding_team: @teams[:responding_team]),
       trig_draft_foi_accepted:   create(:accepted_case,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          responder: responder_user,
                                          approver: disclosure_specialist_user),
       trig_draft_foi:            create(:accepted_case,
                                          :flagged,
                                          :dacu_disclosure,
                                          responder: responder_user),
       trig_pdacu_foi_accepted:   create(:pending_dacu_clearance_case,
                                         approver: disclosure_specialist_user,
                                          responder: responder_user),
       trig_pdacu_foi:            create(:unaccepted_pending_dacu_clearance_case,
                                          responder: responder_user),
       trig_awdis_foi:            create(:case_with_response,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          responder: responder_user,
                                          approver: disclosure_specialist_user),
       trig_responded_foi:        create(:responded_case,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          responder: responder_user,
                                          approver: disclosure_specialist_user),
       trig_closed_foi:           create(:closed_case,
                                          :flagged_accepted,
                                          :dacu_disclosure,
                                          responder: responder_user,
                                          approver: disclosure_specialist_user),
       full_unassigned_foi:       create(:case,
                                          :flagged,
                                          :press_office,
                                          responder: responder_user),
       full_awresp_foi:           create(:assigned_case,
                                         :flagged,
                                         :press_office,
                                         responding_team: responding_team),
       full_awresp_foi_accepted:  create(:assigned_case,
                                         :flagged_accepted,
                                         :press_office,
                                         responding_team: responding_team),
       full_draft_foi:            create(:accepted_case,
                                          :flagged,
                                          :press_office,
                                          responder: responder_user),
       full_pdacu_foi_accepted:   create(:pending_dacu_clearance_case_flagged_for_press_and_private,
                                         approver: disclosure_specialist_user,
                                         responder: responder_user),
       full_ppress_foi:           create(:pending_press_clearance_case,
                                         :flagged,
                                         :press_office,
                                         responder: responder_user),
       full_ppress_foi_accepted:  create(:pending_press_clearance_case,
                                         :flagged_accepted,
                                         :press_office,
                                         responder: responder_user),
       full_pprivate_foi:         create(:pending_private_clearance_case,
                                         :flagged,
                                         :press_office,
                                         responder: responder_user),
       full_pprivate_foi_accepted:create(:pending_private_clearance_case,
                                         :flagged_accepted,
                                         :press_office,
                                         responder: responder_user),
       full_awdis_foi:            create(:case_with_response,
                                        :flagged,
                                        :press_office,
                                        responder: responder_user),
       full_responded_foi:        create(:responded_case,
                                        :flagged,
                                        :press_office,
                                        responder: responder_user),
       full_closed_foi:           create(:closed_case,
                                         :flagged,
                                         :press_office),
    }
  end
  # rubocop:enable Metrics/MethodLength

   def method_missing(method_name, *args)
     if @user_teams&.key?(method_name)
       @user_teams[method_name]
     elsif @users&.key?(method_name)
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
