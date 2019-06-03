require 'csv'

module Stats
  module ETL
    class ClosedCases
      attr_reader :results
      attr_reader :query

      def initialize
        self
          .extract
          .transform
          .load
      end

      def extract
        puts "Extract..."
        @query = Query::ClosedCases.new
        @results = @query.execute

        self
      end

      def transform
        puts "Transform..."
        teams = Team.includes(:users).all
        case_types = CorrespondenceType::SUB_CLASSES_MAP.values.reduce({}) do |memo, sub_classes|
          memo.merge(sub_classes.map { |klass| [klass.to_s, klass.type_abbreviation] }.to_h)
        end

        @results.rows.each do |kase|
          puts "Processing closed case: #{closed_case.first}"

          is_trigger = kase[10] == '1'
          is_sar = CorrespondenceType::SUB_CLASSES_MAP[:SAR].include(kase[1])
          case_type = case_types[kase[1]]
          current_status = I18n.t("helpers.label.state_selector.#{kase[2]}")
          internal_deadline = is_trigger ? kase[6] : nil
          trigger = is_trigger ? 'Yes' : nil
          requester_type = is_sar ? nil : kase[12]&.humanize
          message = dequote_and_truncate(kase[13])
          exemptions = kase[17].map{ |x| CaseClosure::Exemption.section_number_from_id(x) }.join(',')

          # SAR specific
          third_party = humanize_boolean(kase[21])
          reply_method = kase[22]&.humanize
          sar_subject_type = kase[23]&.humanize
          sar_subject_name = kase[24]


          # Duplicates BaseDecorator#late_team_name
          late_team_name =
            if kase[8].present? && kase[7].present? && (kase[8] > kase[7])
              kase[25].blank? ? 'Unspecified' : kase[25]
            else
              'N/A'
            end

          #has_extensions = extension_count(@kase) > 0 ? 'Yes' : 'No'
          #extension_count = sum(26 + 28 - 27 - 29)

          date_created = kase[33].strftime('%F')

           biz_group =  @kase.responding_team&.business_group&.name
          # directorate = @kase.responding_team&.directorate&.name
          # director_general =  @kase.responding_team&.business_group&.team_lead
          # director =  @kase.responding_team&.directorate&.team_lead
          # deputy_director =  @kase.responding_team&.team_lead

          in_time = humanize_boolean(kase[39].present? && kase[39] <= kase[6])
          #in_target = humanize_boolean(kase[41] > 0 && @kase.response_in_target?)
        end

        # Add this to the database table

        self
      end

      def load
        puts "Load..."

        # get all matching data from the data warehouse
        filename = File.join(ENV['HOME'], 'closed-cases.csv')

        CSV.open(filename, "wb") do |csv|
          csv << CSVExporter::CSV_COLUMN_HEADINGS

          @results.rows.each do |closed_case|
            csv << closed_case
          end
        end

        self
      end
    end
  end
end
