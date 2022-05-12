class AddRequesterTypeToCase < ActiveRecord::Migration[5.0]
  def up
    create_enum :requester_type,
      'academic_business_charity',
      'journalist',
      'member_of_the_public',
      'offender',
      'solicitor',
      'staff_judiciary',
      'what_do_they_know'

    add_column :cases, :requester_type, :requester_type
    add_index :cases, :requester_type
  end

  def down
    remove_column :cases, :requester_type

    drop_enum :requester_type
  end
end
