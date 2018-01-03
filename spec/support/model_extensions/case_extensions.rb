require File.join(Rails.root, 'app', 'models', 'case', 'base')


class Case::Base < ApplicationRecord

  def assigned_disclosure_specialist
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.dacu_disclosure.id }
    raise 'No assigned disclosure specialist' if ass.nil? || ass.user.nil?
    ass.user
  end

  def assigned_press_officer
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.press_office.id }
    raise 'No assigned press officer' if ass.nil? || ass.user.nil?
    ass.user
  end

  def assigned_private_officer
    ass = assignments.approving.accepted.detect{ |a| a.team_id == BusinessUnit.private_office.id }
    raise 'No assigned private officer' if ass.nil? || ass.user.nil?
    ass.user
  end

end
