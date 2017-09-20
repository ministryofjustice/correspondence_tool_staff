class UserDecorator < Draper::Decorator
  delegate_all

  def full_name_with_optional_load_html
    if self.teams.include?(BusinessUnit.dacu_disclosure)
      "#{full_name} <strong>(#{cases.opened.count} open cases)</strong>".html_safe
    else
      full_name
    end
  end
end
