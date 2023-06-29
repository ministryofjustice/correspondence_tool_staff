module CurrentTeamAndUser
  module SAR
    class Offender < ::CurrentTeamAndUser::Base
      attr_reader :team, :user

      def initialize(kase)
        super(kase)
        @team = @case.managing_team
        @user = @case&.responder_assignment&.user
      end
    end
  end
end
