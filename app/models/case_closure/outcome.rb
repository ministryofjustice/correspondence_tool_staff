# == Schema Information
#
# Table name: case_closure_metadata
#
#  id                      :integer          not null, primary key
#  type                    :string
#  subtype                 :string
#  name                    :string
#  abbreviation            :string
#  sequence_id             :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  requires_refusal_reason :boolean          default(FALSE)
#  requires_exemption      :boolean          default(FALSE)
#

module CaseClosure
  class Outcome < Metadatum

    def self.granted
      where(abbreviation: 'granted').first
    end

    def self.part_refused
      where(abbreviation: 'part').first
    end

    def self.fully_refused
      where(abbreviation: 'refused').first
    end

    def self.clarify
      where(abbreviation: 'clarify').first
    end

  end
end
