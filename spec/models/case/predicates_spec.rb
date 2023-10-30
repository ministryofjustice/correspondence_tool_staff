require "rails_helper"

describe "Case type predicates" do
  context "when FOI standard" do
    it "replies true to foi and foi standard and false to everything else" do
      kase = create :case
      expect(kase.foi?).to be true
      expect(kase.foi_standard?).to be true
      expect(kase.foi_ir_compliance?).to be false
      expect(kase.foi_ir_timeliness?).to be false
      expect(kase.sar?).to be false
      expect(kase.ico?).to be false
      expect(kase.overturned_ico?).to be false
      expect(kase.overturned_ico_foi?).to be false
      expect(kase.overturned_ico_sar?).to be false
      expect(kase.all_holidays?).to be true
    end
  end

  context "when FOI Internal Review for compliance" do
    it "replies true to foi and foi ir compliance and false to everything else" do
      kase = create :compliance_review
      expect(kase.foi?).to be true
      expect(kase.foi_standard?).to be false
      expect(kase.foi_ir_compliance?).to be true
      expect(kase.foi_ir_timeliness?).to be false
      expect(kase.sar?).to be false
      expect(kase.ico?).to be false
      expect(kase.overturned_ico?).to be false
      expect(kase.overturned_ico_foi?).to be false
      expect(kase.overturned_ico_sar?).to be false
      expect(kase.all_holidays?).to be true
    end
  end

  context "when FOI Internal Review for timeliness" do
    it "replies true to foi and foi_ir_timeliness and false to everything else" do
      kase = create :timeliness_review
      expect(kase.foi?).to be true
      expect(kase.foi_standard?).to be false
      expect(kase.foi_ir_compliance?).to be false
      expect(kase.foi_ir_timeliness?).to be true
      expect(kase.sar?).to be false
      expect(kase.ico?).to be false
      expect(kase.overturned_ico?).to be false
      expect(kase.overturned_ico_foi?).to be false
      expect(kase.overturned_ico_sar?).to be false
      expect(kase.all_holidays?).to be true
    end
  end

  context "when ICO Appeal for FOI" do
    it "replies true to ico and false to everything else" do
      kase = create :ico_foi_case
      expect(kase.foi?).to be false
      expect(kase.foi_standard?).to be false
      expect(kase.foi_ir_compliance?).to be false
      expect(kase.foi_ir_timeliness?).to be false
      expect(kase.sar?).to be false
      expect(kase.ico?).to be true
      expect(kase.overturned_ico?).to be false
      expect(kase.overturned_ico_foi?).to be false
      expect(kase.overturned_ico_sar?).to be false
      expect(kase.all_holidays?).to be true
    end
  end

  context "when ICO Appeal for SAR" do
    it "replies true to ico and false to everything else" do
      kase = create :ico_sar_case
      expect(kase.foi?).to be false
      expect(kase.foi_standard?).to be false
      expect(kase.foi_ir_compliance?).to be false
      expect(kase.foi_ir_timeliness?).to be false
      expect(kase.sar?).to be false
      expect(kase.ico?).to be true
      expect(kase.overturned_ico?).to be false
      expect(kase.overturned_ico_foi?).to be false
      expect(kase.overturned_ico_sar?).to be false
      expect(kase.all_holidays?).to be false
    end
  end
end
