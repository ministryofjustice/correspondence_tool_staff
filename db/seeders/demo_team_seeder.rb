class DemoTeamSeeder

  def run
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
    @bu_dacu_bmt = BusinessUnit.create!(parent: @dir_dacu, name: 'DACU BMT')
    @bu_dacu_dis = BusinessUnit.create!(parent: @dir_dacu, name: 'DACU Disclosure')
    @bu_private = BusinessUnit.create!(parent: @dir_private, name: 'Private Office')
    @bu_press = BusinessUnit.create!(parent: @dir_dacu, name: 'Press Office')

    @bu_laa = BusinessUnit.create!(parent: @dir_laa, name: 'Legal Aid Agency (LAA)')

    @bu_hmctsne = BusinessUnit.create!(parent: @dir_rsus, name: 'North East Regional Support Unit (NE RSU)')

    @bu_hr = BusinessUnit.create!(parent: @dir_hr, name: 'MoJ Human Resouces (HR)')
  end

  def add_leads
    TeamProperty.create!(team: @bg_ops,       key: 'lead', value: 'Ops Leader')
    TeamProperty.create!(team: @bg_hmcts,     key: 'lead', value: 'Chief Taxman')
    TeamProperty.create!(team: @dir_dacu,     key: 'lead', value: 'Dack Headman')
    TeamProperty.create!(team: @dir_private,  key: 'lead', value: 'Lead Privateer')
    TeamProperty.create!(team: @dir_press,    key: 'lead', value: 'Chief Pressman')
    TeamProperty.create!(team: @dir_laa,      key: 'lead', value: 'Kate Adie')
    TeamProperty.create!(team: @dir_hr,       key: 'lead', value: 'Percy Nell')
    TeamProperty.create!(team: @dir_rsus,     key: 'lead', value: 'T. Taxman')
    TeamProperty.create!(team: @bu_dacu_bmt,  key: 'lead', value: 'David Attenborough')
    TeamProperty.create!(team: @bu_dacu_dis,  key: 'lead', value: 'Dasha Diss')
    TeamProperty.create!(team: @bu_private,   key: 'lead', value: 'Primrose Offord')
    TeamProperty.create!(team: @bu_laa,       key: 'lead', value: 'Prescilla Offenberg')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'lead', value: 'Helen Mirren')
    TeamProperty.create!(team: @bu_hr,        key: 'lead', value: 'Harry Redknapp')
  end

  def add_areas_covered
    TeamProperty.create!(team: @bu_laa,       key: 'area', value: 'Operation and administration of the legal aid scheme in England and Wales')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Copies of court file and documents including expert reports')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Care order/proceedings and requests for certificate of conviction')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Listings policy')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Council tax')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Monies received or outstanding')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Confiscation of prohibited items in court buildings')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Info about Jurors & Justices of Peace')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Court fines, paid and outstanding')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Number and nature of Criminal incidents within court buildings')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Court local policy and processes')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'CCTV footage in court premises')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Employment tribunal cases')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Judicial team (Judges Cty & Crown)')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Performance (statistics)')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Data collection returns (including incident reports, Trade Union Time, interpreter returns, failure in service etc.)')
    TeamProperty.create!(team: @bu_hmctsne,   key: 'area', value: 'Areas covered: Cleveland, Durham, Humber Area, Northumbria, North Yorkshire, South Yorkshire, West Yorkshire, ET single Region stats')
  end

  def add_allocatable
    [ @bu_laa, @bu_hmctsne, @bu_hr ].each do |business_unit|
      TeamProperty.create!(team: business_unit, key: can_allocate, value: 'FOI')
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
