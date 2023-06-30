class FixReasonForDeletion < ActiveRecord::Migration[5.0]
  # Changed to be a null migration after discovering that the
  # previous broken migration was never applied anywhere due to
  # other issues - so fixed that one instead
  def change; end
end
