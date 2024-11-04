module CaseFilter
  class VetterFilter < CaseMultiChoicesFilterBase
    VETTING_STATES = %w[ready_for_vetting vetting_in_progress second_vetting_in_progress].freeze

    def self.identifier
      "filter_vetter"
    end

    def self.filter_attributes
      [:filter_vetter]
    end

    def available_choices
      vetters = { "0" => I18n.t("filters.filter_vetter.not_assigned") }
      vetter_ids = Case::SAR::Offender
                     .offender_sar
                     .in_states(VETTING_STATES)
                     .accepted_responding
                     .pluck("assignments.user_id")
                     .uniq
      users_scope = User.where(id: vetter_ids)
      users_scope.each do |user|
        vetters[user.id.to_s] = user.full_name
      end
      { filter_vetter: vetters }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { |c_type| %w[OFFENDER_SAR].include? c_type.abbreviation }
    end

    def call
      records = @records
      filter_vetter(records)
    end

  private

    def filter_vetter(records)
      if @query.filter_vetter.present?
        filters = []
        if @query.filter_vetter.include?("0")
          filters << records
                      .offender_sar
                      .in_states(VETTING_STATES)
                      .where.not(id: Case::SAR::Offender.in_states(VETTING_STATES).accepted_responding.select(:id))
        end
        filters << records.offender_sar
                      .where(
                        id: Case::SAR::Offender
                              .in_states(VETTING_STATES)
                              .accepted_responding
                              .where(
                                assignments: { user_id: @query.filter_vetter },
                              )
                              .select(:id),
                      )
        filters.reduce(Case::Base.none) do |result, filter|
          result.or(filter)
        end
      end
    end
  end
end
