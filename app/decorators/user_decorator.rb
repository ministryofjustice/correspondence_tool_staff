class UserDecorator < Draper::Decorator
  delegate_all

  class << self
    def collection_decorator_class
      PaginatingDecorator
    end
  end

  def full_name_with_optional_load_html
    if self.teams.include?(BusinessUnit.dacu_disclosure)
      "#{full_name} <strong>(#{ h.pluralize(cases.opened.count, 'open case', 'open cases')})</strong>".html_safe
    else
      full_name
    end
  end
end
