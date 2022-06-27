module CaseFilter
  class CaseworkerFilter < CaseMultiChoicesFilterBase

    def self.identifier
      'filter_caseworker'
    end
  
    def self.filter_attributes
      [:filter_caseworker]
    end

    def available_choices
      caseworkers = {"0" => I18n.t("filters.filter_caseworker.not_assigned"),}
      caseworker_ids = Case::SAR::OffenderComplaint
                        .opened
                        .accepted_responding
                        .pluck("assignments.user_id")
                        .uniq
      users_scope = User.where(id: caseworker_ids)
      users_scope.each do | user | 
        caseworkers[user.id.to_s] = user.full_name
      end
      { filter_caseworker: caseworkers}
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { | c_type | ['OFFENDER_SAR_COMPLAINT'].include? c_type.abbreviation }
    end

    def call
      records = @records
      records = filter_caseworker(records)
      records
    end

    private

    def filter_caseworker(records)
      if @query.filter_caseworker.present?
        filters = []
        if @query.filter_caseworker.include?("0")
          filters << records.offender_sar_complaint
                      .opened
                      .where
                      .not(id: Case::SAR::OffenderComplaint.opened.accepted_responding.select(:id))
        end
        filters << records.offender_sar_complaint
                      .opened
                      .where(
                        id: Case::SAR::OffenderComplaint
                            .opened.accepted_responding.where(
                              assignments: {user_id: @query.filter_caseworker})
                            .select(:id))
        filters.reduce(Case::Base.none) do |result, filter|
          result.or(filter)
        end
      end
    end

  end
end
