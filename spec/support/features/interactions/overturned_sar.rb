module Features
  module Interactions
    module OverturnedSAR
      def create_and_assign_overturned_sar_case(user:,
                                                ico_case:,
                                                responding_team:)
        login_step user: user

        kase = create_overturned_sar_case_step(
          ico_case: ico_case,
        )
        assign_case_step business_unit: responding_team
        logout_step
        kase
      end
    end
  end
end
