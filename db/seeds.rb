# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
puts "----Seeding Categories----"
Category.find_or_create_by!(name: 'Freedom of information request', abbreviation: 'FOI', escalation_time_limit: 6, internal_time_limit: 10, external_time_limit: 20)
Category.find_or_create_by!(name: 'General enquiry', abbreviation: 'GQ', escalation_time_limit: 0, internal_time_limit: 10, external_time_limit: 15)



module CaseClosure
  puts "----Seeding CaseClosure::Outcomes----"
  Outcome.find_or_create_by!(subtype: nil, name: 'Granted in full', abbreviation: 'granted', sequence_id: 10)
  Outcome.find_or_create_by!(subtype: nil, name: 'Refused in part', abbreviation: 'part', sequence_id: 20)
  Outcome.find_or_create_by!(subtype: nil, name: 'Refused fully', abbreviation: 'refused', sequence_id: 30)


  puts "----Seeding CaseClosure::RefusalReasons----"
  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: '(s1(3)) or (s8(1)) = Advice & assistance/clarification',
    abbreviation: 'advice',
    sequence_id: 110)

  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: 'Information not held',
    abbreviation: 'noinfo',
    sequence_id: 120)

  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: '(s14(1)) - Vexatious',
    abbreviation: 'vex',
    sequence_id: 130)

  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: '(s14(2)) - Reqpeated request',
    abbreviation: 'repeat',
    sequence_id: 140)

  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: '(s12) - Exceeded cost',
    abbreviation: 'cost',
    sequence_id: 150)

  RefusalReason.find_or_create_by!(
    subtype: nil,
    name: 'Expemption applied',
    abbreviation: 'exempt',
    sequence_id: 160)

  puts "----Seeding CaseClosure::Exemptions----"
  Exemption.find_or_create_by!(
     subtype: 'ncnd',
     name: 'Neither confirm nor deny (NCND)',
     abbreviation: 'ncnd',
     sequence_id: 410)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s21) - Information accessible by other means',
    abbreviation: 'othermeans',
    sequence_id: 510)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s23) - Information supplied by, or relating to, bodies dealing with security matters',
    abbreviation: 'security',
    sequence_id: 520)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s32) - Court records',
    abbreviation: 'court',
    sequence_id: 530)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s34) - Parliamentary privilege',
    abbreviation: 'pp',
    sequence_id: 540)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s40) - Personal information',
    abbreviation: 'pers',
    sequence_id: 550)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s41) - Information provided in confidence',
    abbreviation: 'conf',
    sequence_id: 560)

  Exemption.find_or_create_by!(
    subtype: 'absolute',
    name: '(s44) - Prohibitions on disclosure',
    abbreviation: 'prohib',
    sequence_id: 570)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s22) - Information intended for future publication',
    abbreviation: 'future',
    sequence_id: 605)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s22A) - Research intended for future publication',
    abbreviation: 'research',
    sequence_id: 610)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s24) - National security',
    abbreviation: 'natsec',
    sequence_id: 615)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s26) - Defence',
    abbreviation: 'defence',
    sequence_id: 620)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s27) - International relations',
    abbreviation: 'intrel',
    sequence_id: 625)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s28) - Relations within the United Kingdom',
    abbreviation: 'ukrel',
    sequence_id: 630)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s29) - The economy',
    abbreviation: 'economy',
    sequence_id: 635)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s30) - Investigations and proceedings conducted by public authorities',
    abbreviation: 'pubauth',
    sequence_id: 640)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s31) - Law enforcement',
    abbreviation: 'law',
    sequence_id: 645)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s33) - Audit functions',
    abbreviation: 'audit',
    sequence_id: 650)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s35) - Formulation of government policy',
    abbreviation: 'policy',
    sequence_id: 655)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s36) - Prejudice to effective conduct of public affairs',
    abbreviation: 'prej',
    sequence_id: 660)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s37) - Communication with Her Majesty, etc. and honours',
    abbreviation: 'royals',
    sequence_id: 665)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s38) - Health and safety',
    abbreviation: 'elf',
    sequence_id: 670)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s39) - Environment information',
    abbreviation: 'env',
    sequence_id: 675)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s42) - Legal professional privilege',
    abbreviation: 'legpriv',
    sequence_id: 680)

  Exemption.find_or_create_by!(
    subtype: 'qualified',
    name: '(s43) - Commercial interests',
    abbreviation: 'comm',
    sequence_id: 685)

end


