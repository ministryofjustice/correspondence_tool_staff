class SearchQueryFilterDecorator < Draper::Decorator
  decorates SearchQuery
  delegate_all

  def search_text
    inherited_attribute_value(:search_text)
  end

  def filter_type
    'case_type'
  end

  # def sensitivity
  #   object.query['case_sensitivity']
  # end

  def sensitivity_settings
    {
      'non-trigger' => 'Non-trigger',
      'trigger'     => 'Trigger',
    }
  end

  # def type
  #   object.query['case_type']
  # end

  def type_settings
    {
      'foi-standard' => 'FOI - Standard',
      'foi-ir-compliance' => 'FOI - Internal review for compliance',
      'foi-ir-timeliness' => 'FOI - Internal review for timeliness',
    }
  end
end
