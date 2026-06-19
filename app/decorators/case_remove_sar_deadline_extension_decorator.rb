class CaseRemoveSARDeadlineExtensionDecorator < Draper::Decorator
  decorates Case::Base
  delegate_all

  attr_accessor :reason_for_removing_extension
end
