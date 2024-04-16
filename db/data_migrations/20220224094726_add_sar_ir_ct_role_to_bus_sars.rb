class AddSARIrCtRoleToBusSARs < ActiveRecord::DataMigration
  def up
    sar_ct_id = CorrespondenceType.sar.id
    bu_with_sars = BusinessUnit
                    .joins(:correspondence_type_roles)
                    .where("correspondence_type_roles.correspondence_type_id" => sar_ct_id)

    bu_with_sars.each do |bus_unit|
      case bus_unit.role
      when "manager"
        set_correspondence_type_roles_for_sar_ir(
          bus_unit:,
        )
      when "responder"
        set_correspondence_type_roles_for_sar_ir(
          bus_unit:,
        )
      when "approver"
        set_correspondence_type_roles_for_sar_ir(
          bus_unit:,
        )
      end
    end
  end

  def set_correspondence_type_roles_for_sar_ir(bus_unit:)
    TeamCorrespondenceTypeRole.find_or_create_by(
      team: bus_unit,
      correspondence_type: CorrespondenceType.sar_internal_review,
    )
  end

  def down
    sar_ir_ct_id = CorrespondenceType.sar_internal_review.id

    bu_with_sars = BusinessUnit
                    .joins(:correspondence_type_roles)
                    .where("correspondence_type_roles.correspondence_type_id" => sar_ir_ct_id)

    sar_ir_ct_team_roles = TeamCorrespondenceTypeRole
                             .where(team_id: bu_with_sars.ids,
                                    correspondence_type_id: sar_ir_ct_id)
    sar_ir_ct_team_roles.delete_all
  end
end
