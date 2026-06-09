# Monkey patch gov_uk_date_fields 3.1 to force minimum day/month/year to be 1
# rather than 0, to prevent invalid date calculation errors. gov_uk_date_fields repo is deprecated.
# requires
# CDPTKAN-994
module GovUkDateFields
  class FormFields
    def generate_day_input_field(day_value)
      css_class = "form-control"
      css_class += " form-control-error" if error_for_attr?

      %(
        <div class="form-group form-group-day">
          <label for="#{html_id(:day)}">Day</label>
          <input class="#{css_class}" id="#{html_id(:day)}" name="#{html_name(:day)}" type="number" min="1" max="31" aria-describedby="#{@hint_id}" value="#{day_value}">
        </div>
      )
    end

    def generate_month_input_field(month_value)
      css_class = "form-control"
      css_class += " form-control-error" if error_for_attr?

      %(
        <div class="form-group form-group-month">
          <label for="#{html_id(:month)}">Month</label>
          <input class="#{css_class}" id="#{html_id(:month)}" name="#{html_name(:month)}" type="number" min="1" max="12" value="#{month_value}">
        </div>
      )
    end

    def generate_year_input_field(year_value)
      css_class = "form-control"
      css_class += " form-control-error" if error_for_attr?

      %(
        <div class="form-group form-group-year">
          <label for="#{html_id(:year)}">Year</label>
          <input class="#{css_class}" id="#{html_id(:year)}" name="#{html_name(:year)}" type="number" min="1" max="2100" value="#{year_value}">
        </div>
      )
    end
  end
end
