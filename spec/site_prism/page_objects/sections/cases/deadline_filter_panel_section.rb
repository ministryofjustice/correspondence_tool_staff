module PageObjects
  module Sections
    module Cases
      class DeadlineFilterPanelSection < SitePrism::Section
        element :from_dd, "#search_query_external_deadline_from_dd"
        element :from_mm, "#search_query_external_deadline_from_mm"
        element :from_yyyy, "#search_query_external_deadline_from_yyyy"

        element :to_dd, "#search_query_external_deadline_to_dd"
        element :to_mm, "#search_query_external_deadline_to_mm"
        element :to_yyyy, "#search_query_external_deadline_to_yyyy"

        def from_date=(date)
          date = date.to_date unless date.is_a? Date
          from_dd.set date.day
          from_mm.set date.month
          from_yyyy.set date.year
        end

        def to_date=(date)
          date = date.to_date unless date.is_a? Date
          to_dd.set date.day
          to_mm.set date.month
          to_yyyy.set date.year
        end

        def from_date
          if from_dd.value.present? &&
              from_mm.value.present? &&
              from_yyyy.value.present?

            Date.new(from_yyyy.value.to_i,
                     from_mm.value.to_i,
                     from_dd.value.to_i)

          end
        end

        def to_date
          if to_dd.value.present? &&
              to_mm.value.present? &&
              to_yyyy.value.present?

            Date.new(to_yyyy.value.to_i,
                     to_mm.value.to_i,
                     to_dd.value.to_i)

          end
        end
      end
    end
  end
end
