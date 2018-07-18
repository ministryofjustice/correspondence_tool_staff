module CurrentTeamAndUser
  module ICO
    class Trigger < ::CurrentTeamAndUser::Base
      def awaiting_dispatch_to_ico
        @team = @dts.approving_team
        @user = @case.approver_assignments.for_team(@team).first.user
      end
    end
  end
end
