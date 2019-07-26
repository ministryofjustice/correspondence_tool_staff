class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_commit :warehouse_report

  def warehouse_report
    warehousable = [User, Team, Case::Base, CaseClosure, CaseTransition, TeamProperty]

    # 1. Add current object ot Warehouse?
    return unless warehousable.any? { |type| self.kind_of?(type) }


    # 2. If this object forces a re-warehousing then add a new
    # job

    kases, case_reports = [], []


    if self.kind_of? User
      case_reports = Warehouse::CasesReport.where("creator_id = :user_id OR casework_officer_user_id = :user_id OR responder_id = :user_id", user_id: self.id)
    elsif self.kind_of? Team
      case_reports = Warehouse::CasesReport.where("responding_team_id = :team_id OR business_group_id = :team_id OR directorate_id = :team_id", team_id: self.id)
    elsif self.kind_of? TeamProperty
      case_reports = Warehouse::CasesReport.where("director_general_name_property_id = :property_id OR director_name_property_id = :property_id OR deputy_director_name_property_id = :property_id", property_id: self.id)
    elsif self.kind_of? Case::Base
      kases = [self]
    elsif self.kind_of? CaseClosure
      kases = Case::Base.where("info_held_status_id = :metadata_id OR refusal_reason_id = :metadata_id OR outcome_id = :metadata_id OR appeal_outcome_id = :metadata_id", metadata_id: self.id)
    elsif self.kind_of? CaseTransition
      kases = [self.case]
    else
      nil
    end

    kases.each do |kase|
      Warehouse::CasesReport.generate(kase)
    end

    case_reports.each do |case_report|
      Warehouse::CasesReport.generate(case_report.case)
    end
  end

  def valid_attributes?(attributes)
    attributes.each do |attribute|
      self.class.validators_on(attribute).each do |validator|
        validator.validate_each(self, attribute, send(attribute))
      end
    end
    errors.none?
  end
end
