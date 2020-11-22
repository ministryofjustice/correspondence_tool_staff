module CurrentTeamAndUser
  module SAR
    class Offender < ::CurrentTeamAndUser::Base
      attr_reader :team, :user

      def initialize(kase)
        @case = kase
        @dts = DefaultTeamService.new(@case)
        @team = @case.managing_team
        @user = nil
      end

    end
  end
end
