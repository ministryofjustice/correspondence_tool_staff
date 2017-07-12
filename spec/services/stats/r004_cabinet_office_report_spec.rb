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
        3.times { create :closed_case, :part_refused_exempt }
      end
      # cases created more than 20 days ago still in this quarter
      Timecop.freeze @frozen_time - 30.days do
        3.times { create :case }
        2.times { create :closed_case, :granted_in_full }
        2.times { create :closed_case, :fully_refused_vexatious }
        4.times { create :closed_case, :fully_refused_cost }
        2.times { create :closed_case, :fully_refused_exempt }
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

    context '1.A: Total number of FOI requests received this month' do
      it 'records the total number' do
        expect(@results['1.A'][:desc]).to eq 'Total number of FOI requests received this quarter'
        expect(@results['1.A'][:value]).to eq 30
      end
    end

    context '1.Ai: Of these, number which fall fully or mostly under the Environmental Information Regulations (EIRs)' do
      it 'is out of scope' do
        expect(@results['1.Ai'][:value]).to eq 'N/A'
      end
    end

    context '1.B: Number of requests that have been created but not closed in this quarter' do
      it 'records  the stat' do
        expect(@results['1.B'][:desc]).to eq 'Number of requests that have been created but not closed in this quarter'
        expect(@results['1.B'][:value]).to eq 5
      end
    end

    context '1.Bi: Number of requests where the 20 working day* deadline for response has been extended as permitted in legislation' do
      it 'is out of scope' do
        expect(@results['1.Bi'][:desc]).to eq 'Number of requests where the 20 working day deadline for response has been extended as permitted in legislation'
        expect(@results['1.Bi'][:value]).to eq 'N/A'
      end
    end

    context '1.Bii: Number of requests still outstanding where a fee has been charged or a fee notice issued, including those where where the payment deadline has elapsed and the request has not been processed' do
      it 'is zero' do
        expect(@results['1.Bii'][:desc]).to eq 'Number of requests still outstanding where a fee has been charged or a fee notice issued, including those where where the payment deadline has elapsed and the request has not been processed'
        expect(@results['1.Bii'][:value]).to eq 0
      end
    end

    context '1.Biii: Number of requests created this quarter, that are yet to be closed, that have gone over the 20 day deadline' do
      it 'records the stat' do
        expect(@results['1.Biii'][:desc]).to eq 'Number of requests created this quarter, that are yet to be closed, that have gone over the 20 day deadline'
        expect(@results['1.Biii'][:value]).to eq 3
      end
    end

    context '1.C: Number of requests that have been created and closed within this quarter' do
      it 'records the stat' do
        expect(@results['1.C'][:desc]).to eq 'Number of requests that have been created and closed within this quarter'
        expect(@results['1.C'][:value]).to eq 25
      end
    end

    context '1.Ci: Number of requests created and processed in this quarter that were within time against the external deadline' do
      it 'records the stat' do
        expect(@results['1.Ci'][:desc]).to eq 'Number of requests created and processed in this quarter that were within time against the external deadline'
        expect(@results['1.Ci'][:value]).to eq 22
      end
    end

    context '1.Cii: Number of requests where the 20 working day deadline for response has been extended as permitted in legislation' do
      it 'is out of scope' do
        expect(@results['1.Cii'][:desc]).to eq 'Number of requests where the 20 working day deadline for response has been extended as permitted in legislation'
        expect(@results['1.Cii'][:value]).to eq 'N/A'
      end
    end

    context '1.Ciii: Number of requests that have been created and closed within this quarter that were out of time against the external deadline' do
      it 'is out of scope' do
        expect(@results['1.Ciii'][:desc]).to eq 'Number of requests that have been created and closed within this quarter that were out of time against the external deadline'
        expect(@results['1.Ciii'][:value]).to eq 3
      end
    end

    context '2.A: Number of requests that have been created and closed within this quarter (Replicates \'C\' above in TIMELINESS section)' do
      it 'replicates the figure in 1.C' do
        expect(@results['2.A'][:desc]).to eq 'Number of requests that have been created and closed within this quarter (Replicates \'C\' above in TIMELINESS section)'
        expect(@results['2.A'][:value]).to eq 25
      end
    end

    context "2.B: Number of cases created and closed in this quarter that have been marked as 'Granted in full'" do
      it 'records the stat' do
        expect(@results['2.B'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Granted in full'"
        expect(@results['2.B'][:value]).to eq 7
      end
    end

    context "2.C: Number of cases created and closed in this quarter that have been marked as 'Clarification required - S1(3)'" do
      it 'records the stat' do
        expect(@results['2.C'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Clarification required - S1(3)'"
        expect(@results['2.C'][:value]).to eq 2
      end
    end

    context "2.D: Number of cases created and closed in this quarter that have been marked as 'Refused fully' and with a 'reason for refusal' of 'Information not held'" do
      it 'records the stat' do
        expect(@results['2.D'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' and with a 'reason for refusal' of 'Information not held'"
        expect(@results['2.D'][:value]).to eq 3
      end
    end

    context "2.E: Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(1)) - vexatious'" do
      it 'records the stat' do
        expect(@results['2.E'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(1)) - vexatious'"
        expect(@results['2.E'][:value]).to eq 3
      end
    end

    context "2.F: Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'" do
      it 'records the stat' do
        expect(@results['2.F'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s14(2)) - repeated request'"
        expect(@results['2.F'][:value]).to eq 1
      end
    end

    context "2.G: Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'" do
      it 'records the stat' do
        expect(@results['2.G'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' or 'Refused in part' with a 'reason for refusal' of '(s12) - exceeded cost'"
        expect(@results['2.G'][:value]).to eq 4
      end
    end

    context "2.H: Number of cases created and closed in this quarter that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'" do
      it 'records the stat' do
        expect(@results['2.H'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused in part' with a 'reason for refusal' of 'Exemption applied'"
        expect(@results['2.H'][:value]).to eq 3
      end
    end

    context "2.I: Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'" do
      it 'records the stat' do
        expect(@results['2.I'][:desc]).to eq "Number of cases created and closed in this quarter that have been marked as 'Refused fully' with a 'reason for refusal' of 'Exemption applied'"
        expect(@results['2.I'][:value]).to eq 2
      end
    end


  end
end
