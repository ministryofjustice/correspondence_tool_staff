require "csv"

module Stats
  class R006KiloMap < BaseReport
    COLUMN_HEADINGS = [
      "Business group",
      "Directorate",
      "Business unit",
      "Director General / Director / Deputy Director",
      "Areas covered",
      "Group email",
      "Team member name",
      "Team member email",
    ].freeze

    def self.description
      "Includes a list of all teams and users that respond to requests for information"
    end

    class << self
      def persist_results?
        false
      end
    end

    def results
      @result_set
    end

    def set_results(data)
      @result_set = data
    end

    def report_type
      ReportType.r006
    end

    def filename
      report_type.filename(self.class.report_format)
    end

    # NOTE: Does not run parent constructor
    # rubocop:disable Lint/MissingSuper
    def initialize(**)
      @result_set = [COLUMN_HEADINGS]
    end
    # rubocop:enable Lint/MissingSuper

    def run(*)
      BusinessGroup.order(:name).each { |bg| process_business_group(bg) }
    end

    def to_csv
      @result_set.map do |row|
        row.map { |item| OpenStruct.new(value: item) }
      end
    end

    def period_start
      Time.zone.now
    end

    def period_end
      Time.zone.now
    end

  private

    def process_business_group(business_group)
      line = []
      line << business_group.name
      line << ""
      line << ""
      line << business_group.team_lead
      @result_set << line
      business_group.directorates.order(:name).each { |dir| process_directorate(dir) }
    end

    def process_directorate(dir)
      line = []
      line << ""
      line << dir.name
      line << ""
      line << dir.team_lead
      areas = dir.areas.to_a
      if areas.any?
        line << areas.shift.value
        @result_set << line
        areas.each do |area|
          process_area(area)
        end
      end
      @result_set << line
      dir.business_units.order(:name).each { |bu| process_business_unit(bu) }
    end

    def process_area(area)
      line = []
      line << ""
      line << ""
      line << ""
      line << ""
      line << area.value
      @result_set << line
    end

    def process_business_unit(business_unit)
      line = []
      line << ""
      line << ""
      line << business_unit.name
      line << business_unit.team_lead
      areas = business_unit.areas.to_a
      line << if areas.any?
                areas.shift.value
              else
                ""
              end
      line << business_unit.email
      users = business_unit.users.to_a.sort { |a, b| a.full_name <=> b.full_name }
      if users.any?
        user = users.shift
        line << user.full_name
        line << user&.email
      end
      @result_set << line
      process_areas_and_users(areas, users)
    end

    def process_areas_and_users(areas, users)
      while areas.any? || users.any?
        line = []
        line << ""
        line << ""
        line << ""
        line << ""
        line << if areas.any?
                  areas.shift.value
                else
                  ""
                end
        if users.any?
          line << ""
          user = users.shift
          line << user.full_name
          line << user.email
        end
        @result_set << line
      end
    end
  end
end
