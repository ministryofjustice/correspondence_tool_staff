require "rails_helper"

module ConfigurableStateMachine
  describe DuplicateKeyDetector do
    let(:detector) { described_class.new(filename) }

    context "no duplicate keys" do
      let(:filename) { File.join(File.dirname(__FILE__), "data", "config.yml") }

      describe "#dupes?" do
        it "returns false" do
          detector.run
          expect(detector.dupes?).to be false
        end
      end
    end

    context "duplicate keys in file" do
      let(:filename) { File.join(File.dirname(__FILE__), "data", "config_with_dupes.yml") }

      describe "#dupes?" do
        it "returns true" do
          detector.run
          expect(detector.dupes?).to be true
        end
      end

      describe "#dupe_details?" do
        it "returns false" do
          detector.run
          details = detector.dupe_details
          expect(details.size).to eq 7
          expect(details).to include(" preamble:permitted_case_types:foi: on line 8 duplicates line 6")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned: on line 104 duplicates line 77")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned:add_message_to_case: on line 105 duplicates line 78")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned:assign_responder: on line 106 duplicates line 79")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned:assign_responder:transition_to: on line 107 duplicates line 80")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned:destroy_case: on line 108 duplicates line 81")
          expect(details).to include(" :case_types:workflows:standard:user_roles:manager:states:unassigned:edit_case: on line 109 duplicates line 82")
        end
      end
    end
  end
end
