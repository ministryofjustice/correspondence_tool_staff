class Case::OverturnedICO::BaseDecorator < Case::BaseDecorator

  def internal_deadline
    I18n.l(object.internal_deadline, format: :default)
  end

  def formatted_date_ico_decision_received
    I18n.l(object.date_ico_decision_received, format: :default)
  end

  def ico_decision_summary
    Slim::Template.new do
      <<~EOHTML
      p
        strong
          = "MoJ's decision has been #{object.ico_decision} by the ICO "
        = "on #{ self.formatted_date_ico_decision_received }"
      
      - if #{object.ico_decision_comment.present?}
        p
          = "#{object.ico_decision_comment}"
      EOHTML
    end.render.html_safe
  end
end
