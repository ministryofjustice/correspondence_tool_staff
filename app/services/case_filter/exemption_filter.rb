module CaseFilter
  class ExemptionFilter < CaseFilterBase

    def self.filter_attributes
      [:common_exemption_ids, :exemption_ids]
    end

    def self.process_params!(params)
      process_ids_param(params, 'common_exemption_ids')
      process_ids_param(params, 'exemption_ids')
    end

    def initialize(search_query_record, user, records)
      super
      @exemption_ids = search_query_record.exemption_ids
    end

    def get_availabe_choices
      {
        :common_exemption_ids => self.class.available_common_exemptions,
        :exemption_ids => self.class.available_exemptions
      }
    end

    def is_available?
      @user.permitted_correspondence_types.any? { | c_type | ['FOI', 'OVERTURNED_FOI'].include? c_type.abbreviation }
    end

    # def applied?
    #   @query.exemption_ids.present? || @query.common_exemption_ids.present?
    # end

    def call
      if @exemption_ids.any?
        kase_ids = ids_of_cases_with_all_exemptions
        @records.where(id: kase_ids)
      else
        @records
      end
    end

    def self.available_common_exemptions
      CaseClosure::Exemption.most_frequently_used
    end

    def self.available_exemptions
      CaseClosure::Metadatum.exemption_ncnd_refusal
    end

    def crumbs
      if @exemption_ids.present?
        first_exemption = CaseClosure::Exemption.find(@exemption_ids.first)
        crumb_text = I18n.t "filters.crumbs.exemptions",
                            count: @exemption_ids.count,
                            first_value: first_exemption.name,
                            remaining_values_count: @exemption_ids.count - 1
        params = {
          'common_exemption_ids' => [''],
          'exemption_ids'        => [''],
          'parent_id'            => @query.id,
        }
        [[crumb_text, params]]
      else
        []
      end
    end

    private

    def ids_of_cases_with_all_exemptions
      sql = "select case_id from cases_exemptions where exemption_id in (#{@exemption_ids.join(',')}) group by case_id having count(*) >= #{@exemption_ids.size}"
      CaseExemption.find_by_sql(sql).map(&:case_id)
    end
  end
end
