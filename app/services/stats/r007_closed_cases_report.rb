module Stats
  class R007ClosedCasesReport < BaseCasesReport
    def self.title
      'Closed cases report'
    end

    def self.description
      'Entire list of closed cases'
    end

    def case_scope
      closed_scope = Case::Base.presented_as_closed

      if @user.responder_only?
        case_ids = Assignment.with_teams(@user.responding_teams).pluck(:case_id)
        closed_scope.where(id: case_ids).most_recent_first
      else
        closed_scope.most_recent_first
      end
    end

    def report_type
      ReportType.r007
    end
  end
end

