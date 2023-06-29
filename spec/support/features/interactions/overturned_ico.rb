module Features
  module Interactions
    module OverturnedICO
      def create_and_assign_overturned_ico(user:,
                                           ico_case:,
                                           responding_team:,
                                           flag_for_disclosure:,
                                           do_logout: true)
        login_step(user:)

        kase = create_overturned_ico_case_step(
          ico_case:,
          flagged: flag_for_disclosure,
          case_type: ico_case.original_case_type,
        )

        assign_case_step business_unit: responding_team
        logout_step if do_logout

        kase
      end
    end
  end
end
