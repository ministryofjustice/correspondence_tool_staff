require 'rails_helper'
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')

module Stats
  describe R004CabinetOfficeReport do

    before(:all) do
      @frozen_time = Time.new 2017, 6, 14, 11, 20, 45

      CaseClosure::MetadataSeeder.seed!

      # cases created this quarter
      Timecop.freeze @frozen_time - 2.days do
        2.times { create :case }
        2.times { create :closed_case, :granted_in_full }
        2.times { create :closed_case, :clarification_required }
        3.times { create :closed_case, :refused_fully_info_not_held }
        create :closed_case, :part_refused_vexatious
        create :closed_case, :part_refused_repeat
        3.times { create :closed_case, :part_refused_exempt_s23 }
        4.times { create :closed_case, :fully_refused_exempt_s22 }
        2.times { create :closed_case, :fully_refused_exempt_s23 }
        1.times { create :closed_case, :fully_refused_exempt_s24 }
        4.times { create :closed_case, :fully_refused_exempt_s26 }
        3.times { create :closed_case, :fully_refused_exempt_s27 }
        2.times { create :closed_case, :fully_refused_exempt_s28 }
        1.times { create :closed_case, :fully_refused_exempt_s29 }
        2.times { create :closed_case, :fully_refused_exempt_s30 }
        3.times { create :closed_case, :fully_refused_exempt_s31 }
      end

      # cases created more than 20 days ago still in this quarter
      Timecop.freeze @frozen_time - 30.days do
        3.times { create :case }
        2.times { create :closed_case, :granted_in_full }
        2.times { create :closed_case, :fully_refused_vexatious }
        4.times { create :closed_case, :fully_refused_cost }
        2.times { create :closed_case, :fully_refused_exempt_s21 }
        create :closed_case, :part_refused_exempt_s22a
      end

      # cases created and closed in this quarter but out of time against the external deadline
      Timecop.freeze @frozen_time - 30.days do
        3.times { create :closed_case, :granted_in_full, date_responded: 2.days.ago}
      end


      # cases created  in the previous quarter
      Timecop.freeze @frozen_time  - 3.months do
        create :case
      end


      Timecop.freeze @frozen_time do
        @results = R004CabinetOfficeReport.new.run.results
      end

    end

    after(:all) { DbHousekeeping.clean }

    context '1.A' do
      it 'records the total number' do
        expect(@results['1.A'][:desc]).to eq 'Total number of FOI requests received this quarter'
        expect(@results['1.A'][:value]).to eq 53
      end
    end

    context '1.Ai' do
      it 'is out of scope' do
        expect(@results['1.Ai'][:value]).to eq 'N/A'
      end
    end

    context '1.B' do
      it 'records  the stat' do
        expect(@results['1.B'][:desc]).to eq 'Number of requests that have been created but not closed in this quarter'
        expect(@results['1.B'][:value]).to eq 5
      end
    end

    context '1.Bi' do
      it 'is out of scope' do
        expect(@results['1.Bi'][:desc]).to eq 'Number of requests where the 20 working day deadline for response has been extended as permitted in legislation'
        expect(@results['1.Bi'][:value]).to eq 'N/A'
      end
    end

    context '1.Bii' do
      it 'is zero' do
        expect(@results['1.Bii'][:desc]).to match /Number of requests still outstanding where a fee .* request has not been processed/
        expect(@results['1.Bii'][:value]).to eq 0
      end
    end

    context '1.Biii' do
      it 'records the stat' do
        expect(@results['1.Biii'][:desc]).to eq 'Number of requests created this quarter, that are yet to be closed, that have gone over the 20 day deadline'
        expect(@results['1.Biii'][:value]).to eq 3
      end
    end

    context '1.C' do
      it 'records the stat' do
        expect(@results['1.C'][:desc]).to eq 'Number of requests that have been created and closed within this quarter'
        expect(@results['1.C'][:value]).to eq 48
      end
    end

    context '1.Ci' do
      it 'records the stat' do
        expect(@results['1.Ci'][:desc]).to eq 'Number of requests created and processed in this quarter that were within time against the external deadline'
        expect(@results['1.Ci'][:value]).to eq 45
      end
    end

    context '1.Cii' do
      it 'is out of scope' do
        expect(@results['1.Cii'][:desc]).to eq 'Number of requests where the 20 working day deadline for response has been extended as permitted in legislation'
        expect(@results['1.Cii'][:value]).to eq 'N/A'
      end
    end

    context '1.Ciii' do
      it 'is out of scope' do
        expect(@results['1.Ciii'][:desc]).to eq 'Number of requests that have been created and closed within this quarter that were out of time against the external deadline'
        expect(@results['1.Ciii'][:value]).to eq 3
      end
    end

    context '2.A' do
      it 'replicates the figure in 1.C' do
        expect(@results['2.A'][:desc]).to eq 'Number of requests that have been created and closed within this quarter (Replicates \'C\' above in TIMELINESS section)'
        expect(@results['2.A'][:value]).to eq 48
      end
    end

    context '2.B' do
      it 'records the stat' do
        expect(@results['2.B'][:desc]).to match /Number of cases created and closed in this quarter .*Granted in full/
        expect(@results['2.B'][:value]).to eq 7
      end
    end

    context '2.C' do
      it 'records the stat' do
        expect(@results['2.C'][:desc]).to match /Clarification required - S1\(3\)/
        expect(@results['2.C'][:value]).to eq 2
      end
    end

    context '2.D' do
      it 'records the stat' do
        expect(@results['2.D'][:desc]).to match /Number of cases created and closed in this quarter .*Refused fully.*Information not held/
        expect(@results['2.D'][:value]).to eq 3
      end
    end

    context '2.E' do
      it 'records the stat' do
        expect(@results['2.E'][:desc]).to match /Number of cases created and closed in this quarter .*Refused fully.*Refused in part.* vexatious/
        expect(@results['2.E'][:value]).to eq 3
      end
    end

    context '2.F' do
      it 'records the stat' do
        expect(@results['2.F'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'"
        expect(@results['2.F'][:value]).to eq 1
      end
    end

    context '2.G' do
      it 'records the stat' do
        expect(@results['2.G'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'"
        expect(@results['2.G'][:value]).to eq 4
      end
    end

    context '2.H' do
      it 'records the stat' do
        expect(@results['2.H'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'"
        expect(@results['2.H'][:value]).to eq 3
      end
    end

    context '2.I' do
      it 'records the stat' do
        expect(@results['2.I'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'"
        expect(@results['2.I'][:value]).to eq 25
      end
    end

    context '3.A' do
      it 'records the stat' do
        expect(@results['3.A'][:desc]).to eq "Number of cases created and closed in this quarter that were fully or partly refused"
        expect(@results['3.A'][:value]).to eq 28
      end
    end

    context '3.S22' do
      it 'records the stat' do
        expect(@results['3.S22'][:desc]).to match /Refused fully.*Exemption applied.*Information intended for future publication/
        expect(@results['3.S22'][:value]).to eq 4
      end
    end

    context '3.S22A' do
      it 'records the stat' do
        expect(@results['3.S22A'][:desc]).to match /Refused fully.*reason for refusal.*Research intended for future publication/
        expect(@results['3.S22A'][:value]).to eq 1
      end
    end

    context '3.S23' do
      it 'records the stat' do
        expect(@results['3.S23'][:desc]).to match /Refused fully.*Exemption applied.*Information supplied by, or relating to, bodies dealing with security matters/
        expect(@results['3.S23'][:value]).to eq 2
      end
    end

    context '3.S24' do
      it 'records the stat' do
        expect(@results['3.S24'][:desc]).to match /Refused fully.*Exemption applied.*National security/
        expect(@results['3.S24'][:value]).to eq 1
      end
    end

    context '3.S26' do
      it 'records the stat' do
        expect(@results['3.S26'][:desc]).to match /Refused fully.*Exemption applied.*Defence/
        expect(@results['3.S26'][:value]).to eq 4
      end
    end

    context '3.S27' do
      it 'records the stat' do
        expect(@results['3.S27'][:desc]).to match /Refused fully.*Exemption applied.*International relations/
        expect(@results['3.S27'][:value]).to eq 3
      end
    end

    context '3.S28' do
      it 'records the stat' do
        expect(@results['3.S28'][:desc]).to match /Refused fully.*Exemption applied.*Relations within the United Kingdom/
        expect(@results['3.S28'][:value]).to eq 2
      end
    end

    context '3.S29' do
      it 'records the stat' do
        expect(@results['3.S29'][:desc]).to match /Refused fully.*Exemption applied.*economy/
        expect(@results['3.S29'][:value]).to eq 1
      end
    end

    context '3.S30' do
      it 'records the stat' do
        expect(@results['3.S30'][:desc]).to match /Refused fully.*Exemption applied.*public authorities/
        expect(@results['3.S30'][:value]).to eq 2
      end
    end

    context '3.S31' do
      it 'records the stat' do
        expect(@results['3.S31'][:desc]).to match /Refused fully.*Exemption applied.*Law enforcement/
        expect(@results['3.S31'][:value]).to eq 3
      end
    end

  end
end
