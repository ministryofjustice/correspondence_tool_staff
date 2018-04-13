class CaseFilterService

  def initialize(arel, search_query)
    @arel = arel
    @filter_type = search_query.filter_type
    @query = search_query.query
  end

  def call
    result = nil
    case @query
      when 'internal_review'
        result = @arel.where(type: ['Case::FOI::TimelinessReview', 'Case::FOI::ComplianceReview'])
      when 'timeliness'
        result = @arel.where(type: 'Case::FOI::TimelinessReview')
      when 'compliance'
        result = @arel.where(type: 'Case::FOI::ComplianceReview')
    end
    result
  end
end
