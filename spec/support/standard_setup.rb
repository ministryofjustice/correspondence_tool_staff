class StandardSetup

  include FactoryGirl::Syntax::Methods
  # cases are named <workflow>_<state>_<other> where other may indicate
  # special circumstances, like withing internal escalation deadline, etc.
  #
  # workflows:
  #  * std:    Standard
  #  * trig:   Trigger
  #  * fullap: Full Approval
  #
  # states:
  #   * unassigned
  #   * awresp
  #   * drafting
  #   * pdacu
  #   * press
  #   * private
  #   * awdis
  #   * responded
  #   * closed
  #

  attr_reader :kases

  def initialize
    @teams = {
        bmt_team:               find_or_create(:team_disclosure_bmt),
        disclosure_team:        find_or_create(:team_disclosure),
        press_office_team:      find_or_create(:team_press_office),
        private_office_team:    find_or_create(:team_private_office),
        responding_team:        create(:responding_team),
        other_responding_team:  create(:responding_team)
    }

    @users = {
        bmt_user:                 find_or_create(:disclosure_bmt_user),
        disclosure_user:          find_or_create(:disclosure_specialist),
        another_disclosure_user:  find_or_create(:disclosure_specialist),
        responding_user:          create(:responder),
        other_responder:          create(:responder),
        press_office_user:        find_or_create(:press_officer),
        private_office_user:      find_or_create(:private_officer)
    }

    @kases = {
        std_unassigned_case:  create(:case),
        std_awresp_case:      create(:awaiting_responder_case),
        std_drafting_case:    create(:case_being_drafted, responder: @users[:responding_user]),
        std_awdis_case:       create(:case_with_response, responder: @users[:responding_user]),
        std_responded_case:   create(:responded_case, responder: @users[:responding_user]),
        std_closed_case:      create(:closed_case, responder: @users[:responding_user])
    }
  end


  def method_missing(method_name, *args)
    if method_name.in?(@kases.keys)
      @kases[method_name]
    elsif method_name.in?(@teams.keys)
      @teams[method_name]
    elsif method_name.in?(@users.keys)
      @users[method_name]
    else
      super
    end
  end

end

