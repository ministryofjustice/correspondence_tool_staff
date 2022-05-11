class RemoveGeneralEnquiries < ActiveRecord::Migration[5.0]
  def up
    klass = 'RemoveGeneralEnquiries::Category'.constantize rescue CorrespondenceType
    cat = klass.find_by_name('General enquiry')
    cat.destroy if cat
  end

  def down

  end
end
