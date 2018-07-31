module CurrentTeamAndUser
  module ICO
    class Trigger < ::CurrentTeamAndUser::Base
      def awaiting_dispatch
        @team = @dts.approving_team
        @user = @case.approver_assignments.for_team(@team).first.user
      end

      def awaiting_dispatch
        @team = @dts.approving_team
        @user = @case.approver_assignments.for_team(@team).first.user
      end
    end
  end
end
