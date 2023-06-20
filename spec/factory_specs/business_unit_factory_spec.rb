require "rails_helper"

describe "Business Unit factories" do
  let(:sar) { CorrespondenceType.sar }

  describe ":business_unit" do
    context "without params" do
      it "creates responding team with responding team correspondence_type role for FOI" do
        bu = create :business_unit
        expect(bu.role).to eq "responder"
        expect(bu.correspondence_type_roles.size).to eq 4
        tcr = bu.correspondence_type_roles.first
        expect(tcr).to match_tcr_attrs(:foi, :view, :respond)
      end
    end

    context "with correspondence_types param" do
      it "creates a responding team with correspondence_type role for SAR" do
        bu = create :business_unit, correspondence_type_ids: [sar.id]
        expect(bu.role).to eq "responder"
        expect(bu.correspondence_type_roles.size).to eq 1
        tcr = bu.correspondence_type_roles.first
        expect(tcr).to match_tcr_attrs(:sar, :view, :respond)
      end
    end
  end

  describe "managing_team" do
    context "with no params" do
      it "creates a managing team with correct team correspondence_type roles" do
        bu = create :managing_team
        expect(bu.role).to eq "manager"
        expect(bu.correspondence_type_roles.first)
          .to match_tcr_attrs(:foi, :view, :edit, :manage)
      end
    end

    context "when setting correspondence_type param" do
      it "creates a managing team with correct team correspondence_type roles" do
        bu = create :managing_team, correspondence_type_ids: [sar.id]
        expect(bu.role).to eq "manager"
        expect(bu.correspondence_type_roles.first)
          .to match_tcr_attrs(:sar, :view, :edit, :manage)
      end
    end
  end

  describe "responding_team" do
    context "with no params" do
      it "creates a responding team with correct team correspondence_type roles for both FOI and SAR" do
        bu = create :responding_team

        expect(bu.role).to eq "responder"
        expect(bu.correspondence_type_roles.size).to eq 6
        foi_tcr = bu.correspondence_type_roles.detect do |r|
          r.correspondence_type_id == CorrespondenceType.foi.id
        end
        expect(foi_tcr).to match_tcr_attrs(:foi, :view, :respond)

        sar_tcr = bu.correspondence_type_roles.detect do |r|
          r.correspondence_type_id == CorrespondenceType.sar.id
        end
        expect(sar_tcr).to match_tcr_attrs(:sar, :view, :respond)

        sar_ir_tcr = bu.correspondence_type_roles.detect do |r|
          r.correspondence_type_id == CorrespondenceType.sar_internal_review.id
        end
        expect(sar_ir_tcr).to match_tcr_attrs(:sar_internal_review, :view, :respond)

        ico_tcr = bu.correspondence_type_roles.detect do |r|
          r.correspondence_type_id == CorrespondenceType.ico.id
        end
        expect(ico_tcr).to match_tcr_attrs(:ico, :view, :respond)

        overturned_sar_tcr = bu.correspondence_type_roles.detect do |r|
          r.correspondence_type_id == CorrespondenceType.overturned_sar.id
        end
        expect(overturned_sar_tcr).to match_tcr_attrs(:overturned_sar, :view, :respond)
      end
    end
  end
end
