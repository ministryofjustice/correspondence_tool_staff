class DevTeamSeeder
  def seed!
    Team.reset_column_information
    add_business_groups
    add_directorates
    add_business_units
    add_leads
    add_areas_covered
    add_allocatable
  end

private

  def add_business_groups
    @bg_ops       = BusinessGroup.find_or_create_by!(name: "Operations")
    @bg_hmcts     = BusinessGroup.find_or_create_by!(name: "HMCTS")
  end

  def add_directorates
    @dir_dacu     = Directorate.find_or_create_by!(parent: @bg_ops, name: "Disclosure")
    @dir_private  = Directorate.find_or_create_by!(parent: @bg_ops, name: "Private Office")
    @dir_press    = Directorate.find_or_create_by!(parent: @bg_ops, name: "Press Office")

    @dir_laa      = Directorate.find_or_create_by!(parent: @bg_ops, name: "Legal Aid Agency")
    @dir_hr       = Directorate.find_or_create_by!(parent: @bg_ops, name: "MoJ Human Resources")

    @dir_rsus     = Directorate.find_or_create_by!(parent_id: @bg_hmcts.id, name: "Regional Support Units")
    @dir_prop     = Directorate.find_or_create_by!(parent_id: @bg_hmcts.id, name: "HMCTS Property Directorate")
    @dir_trib     = Directorate.find_or_create_by!(parent_id: @bg_hmcts.id, name: "Upper Tribunals")
    @dir_candi    = Directorate.find_or_create_by!(parent_id: @bg_ops.id, name: "Communications and Information")
  end

  def find_or_create_business_unit(attributes)
    bu = BusinessUnit.find_or_initialize_by(parent_id: attributes[:parent].id, name: attributes[:name])
    bu.update! attributes
    bu
  end

  def add_business_units
    @foi      = CorrespondenceType.foi
    @sar      = CorrespondenceType.sar
    @ico      = CorrespondenceType.ico
    @offender = CorrespondenceType.offender_sar
    @overturned_sar = CorrespondenceType.overturned_sar
    @offender_complaint = CorrespondenceType.offender_sar_complaint

    @bu_dacu_bmt  = find_or_create_business_unit(parent: @dir_dacu,
                                                 name: "Disclosure BMT",
                                                 code: Settings.foi_cases.default_managing_team,
                                                 role: "manager",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_dacu_dis  = find_or_create_business_unit(parent: @dir_dacu,
                                                 name: "Disclosure",
                                                 code: Settings.foi_cases.default_clearance_team,
                                                 role: "approver",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_private   = find_or_create_business_unit(parent: @dir_private,
                                                 name: "Private Office",
                                                 code: Settings.private_office_team_code,
                                                 role: "approver",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_press     = find_or_create_business_unit(parent: @dir_press,
                                                 name: "Press Office",
                                                 code: Settings.press_office_team_code,
                                                 role: "approver",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_laa       = find_or_create_business_unit(parent: @dir_laa,
                                                 name: "Legal Aid Agency (LAA)",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_hr        = find_or_create_business_unit(parent: @dir_hr,
                                                 name: "MoJ Human Resources (MoJ HR)",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_hmctsne   = find_or_create_business_unit(parent: @dir_rsus,
                                                 name: "North East Regional Support Unit (NE RSU)",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id])
    @bu_prop      = find_or_create_business_unit(parent: @dir_prop,
                                                 name: "HMCTS Property Directorate",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_utiac     = find_or_create_business_unit(parent: @dir_trib,
                                                 name: "Upper Tribunal Asylum Chamber",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_utl       = find_or_create_business_unit(parent: @dir_trib,
                                                 name: "Upper Tribunal Lands (UT Lands)",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @overturned_sar.id])
    @bu_uttc      = find_or_create_business_unit(parent: @dir_trib,
                                                 name: "Upper Tibunal - Tax & Chancery Chamber",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @overturned_sar.id])
    @bu_candi     = find_or_create_business_unit(parent: @dir_candi,
                                                 name: "Communications and Information",
                                                 role: "responder",
                                                 correspondence_type_ids: [@foi.id, @sar.id, @ico.id, @overturned_sar.id])
    @bu_branston  = find_or_create_business_unit(parent: @dir_dacu,
                                                 name: "Branston Registry",
                                                 role: "responder",
                                                 correspondence_type_ids: [@offender.id, @offender_complaint.id],
                                                 code: "BRANSTON")
  end
  # rubocop:enable Metrics/MethodLength

  def add_leads
    TeamProperty.find_or_create_by!(team_id: @bg_ops.id,       key: "lead", value: "Ops Leader")
    TeamProperty.find_or_create_by!(team_id: @bg_hmcts.id,     key: "lead", value: "Chief Taxman")
    TeamProperty.find_or_create_by!(team_id: @dir_dacu.id,     key: "lead", value: "Dack Headman")
    TeamProperty.find_or_create_by!(team_id: @dir_private.id,  key: "lead", value: "Lead Privateer")
    TeamProperty.find_or_create_by!(team_id: @dir_press.id,    key: "lead", value: "Chief Pressman")
    TeamProperty.find_or_create_by!(team_id: @dir_laa.id,      key: "lead", value: "Kate Adie")
    TeamProperty.find_or_create_by!(team_id: @dir_hr.id,       key: "lead", value: "Percy Nell")
    TeamProperty.find_or_create_by!(team_id: @dir_rsus.id,     key: "lead", value: "T. Taxman")
    TeamProperty.find_or_create_by!(team_id: @dir_candi.id,    key: "lead", value: "Candi Floss")
    TeamProperty.find_or_create_by!(team_id: @bu_dacu_bmt.id,  key: "lead", value: "David Attenborough")
    TeamProperty.find_or_create_by!(team_id: @bu_dacu_dis.id,  key: "lead", value: "Dasha Diss")
    TeamProperty.find_or_create_by!(team_id: @bu_private.id,   key: "lead", value: "Primrose Offord")
    TeamProperty.find_or_create_by!(team_id: @bu_laa.id,       key: "lead", value: "Prescilla Offenberg")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,   key: "lead", value: "Helen Mirren")
    TeamProperty.find_or_create_by!(team_id: @bu_hr.id,        key: "lead", value: "Harry Redknapp")
    TeamProperty.find_or_create_by!(team_id: @bu_prop.id,      key: "lead", value: "Donald Trump")
    TeamProperty.find_or_create_by!(team_id: @bu_utiac.id,     key: "lead", value: "Ref Ugee")
    TeamProperty.find_or_create_by!(team_id: @bu_utl.id,       key: "lead", value: "Farmer Jones")
    TeamProperty.find_or_create_by!(team_id: @bu_uttc.id,      key: "lead", value: "Gideon Osborne")
    TeamProperty.find_or_create_by!(team_id: @bu_candi.id,     key: "lead", value: "Candi Floss")
    TeamProperty.find_or_create_by!(team_id: @bu_branston.id,  key: "lead", value: "Brian Rix")
  end

  def add_areas_covered
    TeamProperty.find_or_create_by!(team_id: @bu_laa.id,
                                    key: "area",
                                    value: "Operation and administration of the legal aid scheme in England and Wales")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Copies ofbu. court file and documents including expert reports")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Care order/proceedings and requests for certificate of conviction")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Listings policy")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Council tax")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Monies received or outstanding")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Confiscation of prohibited items in court buildings")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Info about Jurors & Justices of Peace")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Court fines, paid and outstanding")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Number and nature of Criminal incidents within court buildings")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Court local policy and processes")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "CCTV footage in court premises")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Employment tribunal cases")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Judicial team (Judges Cty & Crown)")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Performance (statistics)")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Data collection returns (including incident reports, Trade Union Time, interpreter returns, failure in service etc.)")
    TeamProperty.find_or_create_by!(team_id: @bu_hmctsne.id,
                                    key: "area",
                                    value: "Areas covered: Cleveland, Durham, Humber Area, Northumbria, North Yorkshire, South Yorkshire, West Yorkshire, ET single Region stats")
    TeamProperty.find_or_create_by!(team_id: @bu_prop.id,
                                    key: "area",
                                    value: "Property administration")
    TeamProperty.find_or_create_by!(team_id: @bu_utiac.id,
                                    key: "area",
                                    value: "Asylum cases")
    TeamProperty.find_or_create_by!(team_id: @bu_utl.id,
                                    key: "area",
                                    value: "land ownership")
    TeamProperty.find_or_create_by!(team_id: @bu_uttc.id,
                                    key: "area",
                                    value: "Taxing stuff")
    TeamProperty.find_or_create_by!(team_id: @bu_candi.id,
                                    key: "area",
                                    value: "Communicating")
    TeamProperty.find_or_create_by!(team_id: @bu_candi.id,
                                    key: "area",
                                    value: "Replying to requests for information")
  end

  def add_allocatable
    [@bu_laa, @bu_hmctsne, @bu_hr].each do |business_unit|
      TeamProperty.find_or_create_by!(team_id: business_unit.id, key: "can_allocate", value: "FOI")
    end
  end
end
