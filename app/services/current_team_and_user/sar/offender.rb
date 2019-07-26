module CurrentTeamAndUser
  module SAR
    class Offender
      attr_reader :team, :user

      def initialize(kase)
        @case = kase
        @dts = DefaultTeamService.new(@case)
      end

      def data_to_be_requested
        @team = @case.managing_team
        @user = nil
      end

      def waiting_for_data
        @team = @case.managing_team
        @user = nil
      end

      def ready_for_vetting
        @team = @case.managing_team
        @user = nil
      end

      def vetting_in_progress
        @team = @case.managing_team
        @user = nil
      end

      def ready_to_copy
        @team = @case.managing_team
        @user = nil
      end

      def ready_to_dispatch
        @team = @case.managing_team
        @user = nil
      end

      def closed
        @team = @case.managing_team
        @user = nil
      end
    end
  end
end
