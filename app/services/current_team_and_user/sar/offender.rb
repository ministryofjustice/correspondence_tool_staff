module CurrentTeamAndUser
  module SAR
    class Offender
      attr_reader :team, :user

      def initialize(kase)
        @case = kase
        @dts = DefaultTeamService.new(@case)
        @team = @case.managing_team
        @user = nil
      end

      def data_to_be_requested; end

      def waiting_for_data; end

      def ready_for_vetting; end

      def vetting_in_progress; end

      def ready_to_copy; end

      def ready_to_dispatch; end

      def closed; end
    end
  end
end
