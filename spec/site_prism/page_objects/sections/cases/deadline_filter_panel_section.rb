module PageObjects
  module Sections
    module Cases
      class DeadlineFilterPanelSection < SitePrism::Section
        element :from_dd, '#search_query_external_deadline_from_dd'
        element :from_mm, '#search_query_external_deadline_from_mm'
        element :from_yyyy, '#search_query_external_deadline_from_yyyy'

        element :to_dd, '#search_query_external_deadline_to_dd'
        element :to_mm, '#search_query_external_deadline_to_mm'
        element :to_yyyy, '#search_query_external_deadline_to_yyyy'

        element :apply_filter_button, '.button[value="Apply filter"]'

        def from_date=(date)
          date = date.to_date unless date.is_a? Date
          self.from_dd.set date.day
          self.from_mm.set date.month
          self.from_yyyy.set date.year
        end

        def to_date=(date)
          date = date.to_date unless date.is_a? Date
          self.to_dd.set date.day
          self.to_mm.set date.month
          self.to_yyyy.set date.year
        end

        def from_date
          if self.from_dd.value.present? &&
             self.from_mm.value.present? &&
             self.from_yyyy.value.present?

            Date.new(self.from_yyyy.value.to_i,
                     self.from_mm.value.to_i,
                     self.from_dd.value.to_i)

          else
            nil
          end
        end

        def to_date
          if self.to_dd.value.present? &&
             self.to_mm.value.present? &&
             self.to_yyyy.value.present?

            Date.new(self.to_yyyy.value.to_i,
                     self.to_mm.value.to_i,
                     self.to_dd.value.to_i)

          else
            nil
          end
        end
      end
    end
  end
end
