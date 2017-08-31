class DevTeamSeeder

  def seed!
    Team.reset_column_information
    clear_database
    add_business_groups
    add_directorates
    add_business_units
    add_leads
    add_areas_covered
    add_allocatable
  end


  private

  def add_business_groups
    @bg_ops = BusinessGroup.create!(name: 'Operations')
    @bg_hmcts = BusinessGroup.create!(name: 'HMCTS')
  end

  def add_directorates
    @dir_dacu = Directorate.create!(parent: @bg_ops, name: 'DACU')
    @dir_private = Directorate.create!(parent: @bg_ops, name: 'Private Office')
    @dir_press = Directorate.create!(parent: @bg_ops, name: 'Press Office')

    @dir_laa = Directorate.create!(parent: @bg_ops, name: 'Legal Aid Agency')
    @dir_hr = Directorate.create!(parent: @bg_ops, name: 'MoJ Human Resources')

    @dir_rsus = Directorate.create!(parent_id: @bg_hmcts.id, name: 'Regional Support Units')
  end

  def add_business_units
    @bu_dacu_bmt = BusinessUnit.create!(parent: @dir_dacu, name: 'DACU BMT', role: 'manager')
    @bu_dacu_dis = BusinessUnit.create!(parent: @dir_dacu, name: 'DACU Disclosure', role: 'approver')
    @bu_private = BusinessUnit.create!(parent: @dir_private, name: 'Private Office', role: 'approver')
    @bu_press = BusinessUnit.create!(parent: @dir_press, name: 'Press Office', role: 'approver')

    @bu_laa = BusinessUnit.create!(parent: @dir_laa, name: 'Legal Aid Agency (LAA)', role: 'responder')

    @bu_hmctsne = BusinessUnit.create!(parent: @dir_rsus, name: 'North East Regional Support Unit (NE RSU)', role: 'responder')

    @bu_hr = BusinessUnit.create!(parent: @dir_hr, name: 'MoJ Human Resources (MoJ HR)', role: 'responder')
  end

  def add_leads
    TeamProperty.create!(team_id: @bg_ops.id,       key: 'lead', value: 'Ops Leader')
    TeamProperty.create!(team_id: @bg_hmcts.id,     key: 'lead', value: 'Chief Taxman')
    TeamProperty.create!(team_id: @dir_dacu.id,     key: 'lead', value: 'Dack Headman')
    TeamProperty.create!(team_id: @dir_private.id,  key: 'lead', value: 'Lead Privateer')
    TeamProperty.create!(team_id: @dir_press.id,    key: 'lead', value: 'Chief Pressman')
    TeamProperty.create!(team_id: @dir_laa.id,      key: 'lead', value: 'Kate Adie')
    TeamProperty.create!(team_id: @dir_hr.id,       key: 'lead', value: 'Percy Nell')
    TeamProperty.create!(team_id: @dir_rsus.id,     key: 'lead', value: 'T. Taxman')
    TeamProperty.create!(team_id: @bu_dacu_bmt.id,  key: 'lead', value: 'David Attenborough')
    TeamProperty.create!(team_id: @bu_dacu_dis.id,  key: 'lead', value: 'Dasha Diss')
    TeamProperty.create!(team_id: @bu_private.id,   key: 'lead', value: 'Primrose Offord')
    TeamProperty.create!(team_id: @bu_laa.id,       key: 'lead', value: 'Prescilla Offenberg')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'lead', value: 'Helen Mirren')
    TeamProperty.create!(team_id: @bu_hr.id,        key: 'lead', value: 'Harry Redknapp')
  end

  def add_areas_covered
    TeamProperty.create!(team_id: @bu_laa.id,       key: 'area', value: 'Operation and administration of the legal aid scheme in England and Wales')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Copies ofbu. court file and documents including expert reports')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Care order/proceedings and requests for certificate of conviction')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Listings policy')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Council tax')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Monies received or outstanding')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Confiscation of prohibited items in court buildings')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Info about Jurors & Justices of Peace')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Court fines, paid and outstanding')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Number and nature of Criminal incidents within court buildings')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Court local policy and processes')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'CCTV footage in court premises')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Employment tribunal cases')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Judicial team (Judges Cty & Crown)')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Performance (statistics)')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Data collection returns (including incident reports, Trade Union Time, interpreter returns, failure in service etc.)')
    TeamProperty.create!(team_id: @bu_hmctsne.id,   key: 'area', value: 'Areas covered: Cleveland, Durham, Humber Area, Northumbria, North Yorkshire, South Yorkshire, West Yorkshire, ET single Region stats')
  end

  def add_allocatable
    [ @bu_laa, @bu_hmctsne, @bu_hr ].each do |business_unit|
      TeamProperty.create!(team_id: business_unit.id, key: 'can_allocate', value: 'FOI')
    end
  end



  def clear_database
    tables = %w(
      assignments
      case_attachments
      case_transitions
      cases
      cases_exemptions
      team_properties
      teams
      teams_users_roles
      users
    )
    tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
  end

end
