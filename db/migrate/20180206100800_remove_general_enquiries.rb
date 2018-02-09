class RemoveGeneralEnquiries < ActiveRecord::Migration[5.0]
  def up
    klass = 'Category'.constantize rescue CorrespondenceType
    cat = klass.find_by_name('General enquiry')
    cat.destroy if cat
  end

  def down

  end
end
