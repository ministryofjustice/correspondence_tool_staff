class RemoveGeneralEnquiries < ActiveRecord::Migration[5.0]
  def up
    cat = Category.find_by_name('General enquiry')
    cat.destroy if cat
  end

  def down

  end
end
