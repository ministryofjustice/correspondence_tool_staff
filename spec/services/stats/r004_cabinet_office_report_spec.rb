require "rails_helper"
require File.join(Rails.root, "db", "seeders", "case_closure_metadata_seeder")

module Stats
  describe R004CabinetOfficeReport do
    describe "sections 1, 2, 3, 5, 6, 7" do
      before(:all) do
        create_report_type(abbr: :r004)

        @frozen_time = Time.zone.local 2017, 6, 14, 11, 20, 45

        CaseClosure::MetadataSeeder.seed!

        # cases created this quarter
        Timecop.freeze @frozen_time - 2.days do
          create_list :case, 2
          create :case, :extended_for_pit
          create_list :awaiting_responder_compliance_review, 2, :extended_for_pit
          create_list :accepted_timeliness_review, 3, :extended_for_pit
          create_list :closed_case, 2
          create_list :closed_case, 2, :extended_for_pit
          create_list :closed_case, 2, :clarification_required
          create_list :closed_case, 3, :info_not_held

          create :closed_case, :other_vexatious
          create :closed_case, :other_repeat
          create_list :closed_case, 2, :other_exceeded_cost
          create_list :closed_case, 3, :part_refused_exempt_s23

          create_list :closed_case, 3, :fully_refused_exempt_s22
          create_list :closed_case, 2, :fully_refused_exempt_s23
          create :closed_case, :fully_refused_exempt_s24
          create_list :closed_case, 4, :fully_refused_exempt_s26

          create :closed_case, :fully_refused_exempt_s27
          create_list :closed_case, 2, :fully_refused_exempt_s28
          create :closed_case, :fully_refused_exempt_s29
          create_list :closed_case, 2, :fully_refused_exempt_s30

          create_list :closed_case, 3, :fully_refused_exempt_s31
          create_list :closed_case, 2, :fully_refused_exempt_s32
          create :closed_case, :fully_refused_exempt_s33
          create_list :closed_case, 2, :fully_refused_exempt_s34

          create :closed_case, :fully_refused_exempt_s35
          create_list :closed_case, 2, :fully_refused_exempt_s36
          create :closed_case, :fully_refused_exempt_s37
          create_list :closed_case, 2, :fully_refused_exempt_s38

          create :closed_case, :fully_refused_exempt_s40
          create_list :closed_case, 2, :fully_refused_exempt_s41
          create :closed_case, :fully_refused_exempt_s42
          create_list :closed_case, 2, :fully_refused_exempt_s43
          create :closed_case, :fully_refused_exempt_s44

          create_list :closed_case, 2, :with_ncnd_exemption

          create(:ico_foi_case, original_case: create(:closed_foi_ir_compliance, :fully_refused_exempt_s22))
          2.times { create(:ico_foi_case, original_case: create(:closed_foi_ir_compliance, :fully_refused_exempt_s27)) }
          3.times { create(:ico_foi_case, original_case: create(:closed_case, :fully_refused_exempt_s34)) }
          4.times { create(:ico_foi_case, original_case: create(:closed_case, :fully_refused_exempt_s36)) }
          2.times { create(:ico_foi_case, original_case: create(:closed_case, :fully_refused_exempt_s44)) }
          3.times { create(:ico_foi_case, original_case: create(:closed_case, :info_not_held)) }
          6.times { create(:closed_ico_foi_case, original_case: create(:closed_case, :fully_refused_exempt_s21)) }

          3.times { create(:closed_ico_foi_case, original_case: create(:closed_case, :fully_refused_exempt_s12_1)) }
          2.times { create(:closed_ico_foi_case, original_case: create(:closed_case, :other_exceeded_cost)) }

          2.times { create(:closed_ico_foi_case, original_case: create(:closed_case, :other_vexatious)) }
          create(:closed_ico_foi_case, original_case: create(:closed_case, :other_repeat))

          3.times { create(:closed_ico_foi_case, original_case: create(:closed_case, :with_ncnd_exemption)) }
        end

        # cases created more than 20 days ago still in this quarter
        Timecop.freeze @frozen_time - 60.days do
          create_list :case, 2, :extended_for_pit
        end

        # cases created more than 20 days ago still in this quarter
        Timecop.freeze @frozen_time - 30.days do
          create_list :case, 3
          create_list :closed_case, 2
          create_list :closed_case, 2, :other_vexatious
          create_list :closed_case, 4, :fully_refused_exempt_s12_1
          create_list :closed_case, 2, :fully_refused_exempt_s21
          create :closed_case, :fully_refused_exempt_s22a
        end

        # cases created and closed in this quarter but out of time against the external deadline
        Timecop.freeze @frozen_time - 30.days do
          create_list :closed_case, 3, :granted_in_full, date_responded: 2.days.ago
        end

        # cases created  in the previous quarter
        Timecop.freeze @frozen_time - 3.months do
          create :case
        end

        Timecop.freeze @frozen_time do
          @results = described_class.new.run.results
        end
      end

      after(:all) { DbHousekeeping.clean(seed: true) }

      describe "1.A" do
        it "records the total number" do
          expect(@results["1.A"][:desc]).to eq "Total number of FOI requests received this period"
          expect(@results["1.A"][:value]).to eq 102
        end
      end

      describe "1.Ai" do
        it "is out of scope" do
          expect(@results["1.Ai"][:value]).to eq "N/A"
        end
      end

      describe "1.B" do
        it "records  the stat" do
          expect(@results["1.B"][:desc]).to eq "Number of requests that have been created but not closed in this period"
          expect(@results["1.B"][:value]).to eq 9
        end
      end

      describe "1.Bi" do
        it "records the stat" do
          expect(@results["1.Bi"][:desc]).to eq "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation"
          expect(@results["1.Bi"][:value]).to eq 3
        end
      end

      describe "1.Bii" do
        it "is zero" do
          expect(@results["1.Bii"][:desc]).to match(/Number of requests still outstanding where a fee .* request has not been processed/)
          expect(@results["1.Bii"][:value]).to eq 0
        end
      end

      describe "1.Biii" do
        it "records the stat" do
          expect(@results["1.Biii"][:desc]).to eq "Number of requests created this period, that are yet to be closed, that have gone over the 20 day deadline"
          expect(@results["1.Biii"][:value]).to eq 4
        end
      end

      describe "1.C" do
        it "records the stat" do
          expect(@results["1.C"][:desc]).to eq "Number of requests that have been created and closed within this period"
          expect(@results["1.C"][:value]).to eq 93
        end
      end

      describe "1.Ci" do
        it "records the stat" do
          expect(@results["1.Ci"][:desc]).to eq "Number of requests created and processed in this period that were within time against the external deadline"
          expect(@results["1.Ci"][:value]).to eq 88
        end
      end

      describe "1.Cii" do
        it "records the stat" do
          expect(@results["1.Cii"][:desc]).to eq "Number of requests where the 20 working day deadline for response has been extended as permitted in legislation"
          expect(@results["1.Cii"][:value]).to eq 2
        end
      end

      describe "1.Ciii" do
        it "is out of scope" do
          expect(@results["1.Ciii"][:desc]).to eq "Number of requests that have been created and closed within this period that were out of time against the external deadline"
          expect(@results["1.Ciii"][:value]).to eq 3
        end
      end

      describe "2.A" do
        it "replicates the figure in 1.C" do
          expect(@results["2.A"][:desc]).to eq "Number of requests that have been created and closed within this period (Replicates 'C' above in TIMELINESS section)"
          expect(@results["2.A"][:value]).to eq 93
        end
      end

      describe "2.B" do
        it "records the stat" do
          expect(@results["2.B"][:desc]).to match(/Number of cases created and closed in this period .*Granted in full/)
          expect(@results["2.B"][:value]).to eq 12
        end
      end

      describe "2.C" do
        it "records the stat" do
          expect(@results["2.C"][:desc]).to match(/Clarification required - S1\(3\)/)
          expect(@results["2.C"][:value]).to eq 2
        end
      end

      describe "2.D" do
        it "records the stat" do
          expect(@results["2.D"][:desc]).to match(/Number of cases created and closed in this period .*Refused fully.*Information not held/)
          expect(@results["2.D"][:value]).to eq 6
        end
      end

      describe "2.E" do
        it "records the stat" do
          expect(@results["2.E"][:desc]).to match(/Number of cases created and closed in this period .*Refused fully.*Refused in part.* vexatious/)
          expect(@results["2.E"][:value]).to eq 5
        end
      end

      describe "2.F" do
        it "records the stat" do
          expect(@results["2.F"][:desc]).to eq "Number of cases created and closed in this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'"
          expect(@results["2.F"][:value]).to eq 2
        end
      end

      describe "2.G" do
        it "records the stat" do
          expect(@results["2.G"][:desc]).to eq "Number of cases created and closed in this period that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'"
          expect(@results["2.G"][:value]).to eq 11
        end
      end

      describe "2.H" do
        it "records the stat" do
          expect(@results["2.H"][:desc]).to eq "Number of cases created and closed in this period that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'"
          expect(@results["2.H"][:value]).to eq 3
        end
      end

      describe "2.I" do
        it "records the stat" do
          expect(@results["2.I"][:desc]).to eq "Number of cases created and closed in this period that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'"
          expect(@results["2.I"][:value]).to eq 52
        end
      end

      describe "3.A" do
        it "records the stat" do
          expect(@results["3.A"][:desc]).to eq "Number of cases created and closed in this period that were fully or partly refused. = 2.H + 2.I"
          expect(@results["3.A"][:value]).to eq 55
        end
      end

      describe "3.S22" do
        it "records the stat" do
          expect(@results["3.S22"][:desc]).to match(/Information intended for future publication/)
          expect(@results["3.S22"][:value]).to eq 3
        end
      end

      describe "3.S22A" do
        it "records the stat" do
          expect(@results["3.S22A"][:desc]).to match(/Research intended for future publication/)
          expect(@results["3.S22A"][:value]).to eq 1
        end
      end

      describe "3.S23" do
        it "records the stat" do
          expect(@results["3.S23"][:desc]).to match(/Information supplied by, or relating to, bodies dealing with security matters/)
          expect(@results["3.S23"][:value]).to eq 5
        end
      end

      describe "3.S24" do
        it "records the stat" do
          expect(@results["3.S24"][:desc]).to match(/National security/)
          expect(@results["3.S24"][:value]).to eq 1
        end
      end

      describe "3.S26" do
        it "records the stat" do
          expect(@results["3.S26"][:desc]).to match(/Defence/)
          expect(@results["3.S26"][:value]).to eq 4
        end
      end

      describe "3.S27" do
        it "records the stat" do
          expect(@results["3.S27"][:desc]).to match(/International relations/)
          expect(@results["3.S27"][:value]).to eq 1
        end
      end

      describe "3.S28" do
        it "records the stat" do
          expect(@results["3.S28"][:desc]).to match(/Relations within the United Kingdom/)
          expect(@results["3.S28"][:value]).to eq 2
        end
      end

      describe "3.S29" do
        it "records the stat" do
          expect(@results["3.S29"][:desc]).to match(/economy/)
          expect(@results["3.S29"][:value]).to eq 1
        end
      end

      describe "3.S30" do
        it "records the stat" do
          expect(@results["3.S30"][:desc]).to match(/public authorities/)
          expect(@results["3.S30"][:value]).to eq 2
        end
      end

      describe "3.S31" do
        it "records the stat" do
          expect(@results["3.S31"][:desc]).to match(/Law enforcement/)
          expect(@results["3.S31"][:value]).to eq 3
        end
      end

      describe "3.S32" do
        it "records the stat" do
          expect(@results["3.S32"][:desc]).to match(/Court records/)
          expect(@results["3.S32"][:value]).to eq 2
        end
      end

      describe "3.S33" do
        it "records the stat" do
          expect(@results["3.S33"][:desc]).to match(/Audit functions/)
          expect(@results["3.S33"][:value]).to eq 1
        end
      end

      describe "3.S34" do
        it "records the stat" do
          expect(@results["3.S34"][:desc]).to match(/Parliamentary privilege/)
          expect(@results["3.S34"][:value]).to eq 5
        end
      end

      describe "3.S35" do
        it "records the stat" do
          expect(@results["3.S35"][:desc]).to match(/Formulation of government policy/)
          expect(@results["3.S35"][:value]).to eq 1
        end
      end

      describe "3.S36" do
        it "records the stat" do
          expect(@results["3.S36"][:desc]).to match(/Prejudice to effective conduct of public affairs/)
          expect(@results["3.S36"][:value]).to eq 6
        end
      end

      describe "3.S37" do
        it "records the stat" do
          expect(@results["3.S37"][:desc]).to match(/Communications with Her Majesty, etc. and honours/)
          expect(@results["3.S37"][:value]).to eq 1
        end
      end

      describe "3.S38" do
        it "records the stat" do
          expect(@results["3.S38"][:desc]).to match(/Health and safety/)
          expect(@results["3.S38"][:value]).to eq 2
        end
      end

      describe "3.S40" do
        it "records the stat" do
          expect(@results["3.S40"][:desc]).to match(/Personal information/)
          expect(@results["3.S40"][:value]).to eq 1
        end
      end

      describe "3.S41" do
        it "records the stat" do
          expect(@results["3.S41"][:desc]).to match(/Information provided in confidence/)
          expect(@results["3.S41"][:value]).to eq 2
        end
      end

      describe "3.S42" do
        it "records the stat" do
          expect(@results["3.S42"][:desc]).to match(/Legal professional privilege/)
          expect(@results["3.S42"][:value]).to eq 1
        end
      end

      describe "3.S43" do
        it "records the stat" do
          expect(@results["3.S43"][:desc]).to match(/Commercial interests/)
          expect(@results["3.S43"][:value]).to eq 2
        end
      end

      describe "3.S44" do
        it "records the stat" do
          expect(@results["3.S44"][:desc]).to match(/Prohibitions on disclosure/)
          expect(@results["3.S44"][:value]).to eq 3
        end
      end

      describe "5.Ai" do
        it "records the stat" do
          expect(@results["5.Ai"][:desc]).to match(/Number of cases created in this period .*Information not held/)
          expect(@results["5.Ai"][:value]).to eq 3
        end
      end

      describe "6.S12" do
        it "records the stat" do
          expect(@results["6.S12"][:desc]).to match(/Number of cases created in this period .*Exceeded cost to investigate/)
          expect(@results["6.S12"][:value]).to eq 5
        end
      end

      describe "6.S14" do
        it "records the stat" do
          expect(@results["6.S14"][:desc]).to match(/Number of cases created in this period .*Vexatious.*Repeated request/)
          expect(@results["6.S14"][:value]).to eq 3
        end
      end

      describe "7.S21" do
        it "records the stat" do
          expect(@results["7.S21"][:desc]).to match(/Information accessible by other means/)
          expect(@results["7.S21"][:value]).to eq 6
        end
      end

      describe "7.S22" do
        it "records the stat" do
          expect(@results["7.S22"][:desc]).to match(/Information intended for future publication/)
          expect(@results["7.S22"][:value]).to eq 1
        end
      end

      describe "7.S22A" do
        it "records the stat" do
          expect(@results["7.S22A"][:desc]).to match(/Research intended for future publication/)
          expect(@results["7.S22A"][:value]).to eq 0
        end
      end

      describe "7.S23" do
        it "records the stat" do
          expect(@results["7.S23"][:desc]).to match(/Information supplied by, or relating to, bodies dealing with security matters/)
          expect(@results["7.S23"][:value]).to eq 0
        end
      end

      describe "7.S24" do
        it "records the stat" do
          expect(@results["7.S24"][:desc]).to match(/National security/)
          expect(@results["7.S24"][:value]).to eq 0
        end
      end

      describe "7.S26" do
        it "records the stat" do
          expect(@results["7.S26"][:desc]).to match(/Defence/)
          expect(@results["7.S26"][:value]).to eq 0
        end
      end

      describe "7.S27" do
        it "records the stat" do
          expect(@results["7.S27"][:desc]).to match(/International relations/)
          expect(@results["7.S27"][:value]).to eq 2
        end
      end

      describe "7.S28" do
        it "records the stat" do
          expect(@results["7.S28"][:desc]).to match(/Relations within the United Kingdom/)
          expect(@results["7.S28"][:value]).to eq 0
        end
      end

      describe "7.S29" do
        it "records the stat" do
          expect(@results["7.S29"][:desc]).to match(/economy/)
          expect(@results["7.S29"][:value]).to eq 0
        end
      end

      describe "7.S30" do
        it "records the stat" do
          expect(@results["7.S30"][:desc]).to match(/public authorities/)
          expect(@results["7.S30"][:value]).to eq 0
        end
      end

      describe "7.S31" do
        it "records the stat" do
          expect(@results["7.S31"][:desc]).to match(/Law enforcement/)
          expect(@results["7.S31"][:value]).to eq 0
        end
      end

      describe "7.S32" do
        it "records the stat" do
          expect(@results["7.S32"][:desc]).to match(/Court records/)
          expect(@results["7.S32"][:value]).to eq 0
        end
      end

      describe "7.S33" do
        it "records the stat" do
          expect(@results["7.S33"][:desc]).to match(/Audit functions/)
          expect(@results["7.S33"][:value]).to eq 0
        end
      end

      describe "7.S34" do
        it "records the stat" do
          expect(@results["7.S34"][:desc]).to match(/Parliamentary privilege/)
          expect(@results["7.S34"][:value]).to eq 3
        end
      end

      describe "7.S35" do
        it "records the stat" do
          expect(@results["7.S35"][:desc]).to match(/Formulation of government policy/)
          expect(@results["7.S35"][:value]).to eq 0
        end
      end

      describe "7.S36" do
        it "records the stat" do
          expect(@results["7.S36"][:desc]).to match(/Prejudice to effective conduct of public affairs/)
          expect(@results["7.S36"][:value]).to eq 4
        end
      end

      describe "7.S37" do
        it "records the stat" do
          expect(@results["7.S37"][:desc]).to match(/Communications with Her Majesty, etc. and honours/)
          expect(@results["7.S37"][:value]).to eq 0
        end
      end

      describe "7.S38" do
        it "records the stat" do
          expect(@results["7.S38"][:desc]).to match(/Health and safety/)
          expect(@results["7.S38"][:value]).to eq 0
        end
      end

      describe "7.S40" do
        it "records the stat" do
          expect(@results["7.S40"][:desc]).to match(/Personal information/)
          expect(@results["7.S40"][:value]).to eq 0
        end
      end

      describe "7.S41" do
        it "records the stat" do
          expect(@results["7.S41"][:desc]).to match(/Information provided in confidence/)
          expect(@results["7.S41"][:value]).to eq 0
        end
      end

      describe "7.S42" do
        it "records the stat" do
          expect(@results["7.S42"][:desc]).to match(/Legal professional privilege/)
          expect(@results["7.S42"][:value]).to eq 0
        end
      end

      describe "7.S43" do
        it "records the stat" do
          expect(@results["7.S43"][:desc]).to match(/Commercial interests/)
          expect(@results["7.S43"][:value]).to eq 0
        end
      end

      describe "7.S44" do
        it "records the stat" do
          expect(@results["7.S44"][:desc]).to match(/Prohibitions on disclosure/)
          expect(@results["7.S44"][:value]).to eq 2
        end
      end
    end

    describe "section 4" do
      before(:all) do
        create_report_type(abbr: :r004)

        @frozen_time = Time.zone.local 2017, 6, 14, 11, 20, 45
        CaseClosure::MetadataSeeder.seed!

        # cases created this quarter
        Timecop.freeze @frozen_time - 2.days do
          # cases created this quarter with S21 being the only exemption in time
          create :closed_case, :fully_refused_exempt_s21
          create_list :closed_case, 2, :fully_refused_exempt_s21

          # cases created this quarter with S21 being the only exemption but out of time
          Timecop.freeze @frozen_time - 30.days do
            create_list :closed_case, 3, :fully_refused_exempt_s21, date_responded: 1.day.ago
            create_list :closed_case, 4, :fully_refused_exempt_s21, date_responded: 1.day.ago
          end

          # cases created this quarter with S21 being one of several exemptions
          3.times do
            rec = create :closed_case, :fully_refused_exempt_s21
            rec.exemptions << CaseClosure::Exemption.s34
            rec.save!
          end
        end

        Timecop.freeze @frozen_time do
          @results = described_class.new.run.results
        end
      end

      after(:all) { DbHousekeeping.clean(seed: true) }

      describe "4.A" do
        it "counts the number of cases with just one exception s21 including in time and out of time" do
          expect(@results["4.A"][:desc]).to match(/Refused fully.*Refused in part.*Exemption applied.*Information accessible by other means/)
          expect(@results["4.A"][:value]).to eq 10
        end
      end

      describe "4.B" do
        it "counts the number of cases with just one exception s21 including in time only" do
          expect(@results["4.B"][:desc]).to match(/Refused fully.*Refused in part.*Exemption applied.*Information accessible by other means.*IN TIME/)
          expect(@results["4.B"][:value]).to eq 3
        end
      end

      describe "4.C" do
        it "counts the number of cases with just one exception s21 including in time only" do
          expect(@results["4.C"][:desc]).to match(/Refused fully.*Refused in part.*Exemption applied.*Information accessible by other means.*OUT OF TIME/)
          expect(@results["4.C"][:value]).to eq 7
        end
      end
    end
  end
end
