module CaseFilter
  class ExemptionFilter < CaseMultiChoicesFilterBase

    class << self
      def identifier
        "filter_exemption"
      end
    
      def filter_attributes
        [:common_exemption_ids, :exemption_ids]
      end

      def filter_fields(filter_fields)
        filter_fields[:common_exemption_ids] = [:integer, array: true, default: []]
        filter_fields[:exemption_ids] = [:integer, array: true, default: []]
      end

      def process_params!(params)
        process_ids_param(params, 'common_exemption_ids')
        process_ids_param(params, 'exemption_ids')
      end
    end

    def initialize(query, user, records)
      super
      @exemption_ids = @query.exemption_ids
      @exemption_ids += @query.common_exemption_ids || []
      @exemption_ids = @exemption_ids.uniq
    end

    def available_choices
      {
        common_exemption_ids: self.class.available_common_exemptions,
        exemption_ids: self.class.available_exemptions
      }
    end

    def is_permitted_for_user?
      @user.permitted_correspondence_types.any? { | c_type | %w[FOI OVERTURNED_FOI].include? c_type.abbreviation }
    end

    def call
      if @exemption_ids.any?
        kase_ids = ids_of_cases_with_all_exemptions
        @records.where(id: kase_ids)
      else
        @records
      end
    end

    def self.available_common_exemptions
      choices = {}
      CaseClosure::Exemption.most_frequently_used.each do | item |
        choices[item.id] = item.name
      end
      choices
    end

    def self.available_exemptions
      choices = {}
      CaseClosure::Metadatum.exemption_ncnd_refusal.each do | item |
        choices[item.id] = item.name
      end
      choices
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
      sql = "select case_id from cases_exemptions where exemption_id in (?) group by case_id having count(*) >= ?"

      CaseExemption.find_by_sql([sql, @exemption_ids, @exemption_ids.count]).map(&:case_id)
    end
  end
end
