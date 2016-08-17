# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
puts "----Seeding Categories----"
Category.find_or_create_by!(name: 'Freedom of information request', abbreviation: 'FOI', internal_time_limit: 9, external_time_limit: 19)
Category.find_or_create_by!(name: 'General enquiry', abbreviation: 'GQ', internal_time_limit: 9, external_time_limit: 14)
