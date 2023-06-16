class RemoveGeneralEnquiries < ActiveRecord::Migration[5.0]
  def up
    klass = begin
      "RemoveGeneralEnquiries::Category".constantize
    rescue StandardError
      CorrespondenceType
    end
    cat = klass.find_by_name("General enquiry")
    cat.destroy! if cat
  end

  def down; end
end
