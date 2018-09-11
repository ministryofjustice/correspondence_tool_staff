class Case::ICO::BaseDecorator < Case::BaseDecorator

  attr_accessor :original_case_number, :related_case_number

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
          = " #{object.ico_decision_comment}"
      EOHTML
    end.render.html_safe
  end

end
