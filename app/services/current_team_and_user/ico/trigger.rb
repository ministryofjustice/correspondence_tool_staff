module CurrentTeamAndUser
  module ICO
    class Trigger < ::CurrentTeamAndUser::Base
      def awaiting_dispatch_for_ico
        @team = @case.responding_team
        @user = @case.responder
      end
    end
  end
end
