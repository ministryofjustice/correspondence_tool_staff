class Case::OverturnedICO::BaseDecorator < Case::BaseDecorator

  def internal_deadline
    I18n.l(object.internal_deadline, format: :default)
  end
end
