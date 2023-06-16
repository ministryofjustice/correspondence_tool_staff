require "cts"

module CTS::Cases
  class Check
    def initialize(kase_id_or_number, options)
      @case = CTS.find_case(kase_id_or_number)
      @options = options
    end

    def call
      check_methods = public_methods.grep(/^check_/)
      check_methods.each do |check_method|
        error_count = 0
        begin
          __send__(check_method, @case)
        rescue StandardError => e
          CTS.error("!!! check '#{check_method}' failed for case #{@case.number} id:#{@case.id}")
          CTS.error("!!! - #{e.message}")
          error_count += 1
          if @options[:trace]
            CTS.error(e.backtrace.grep(/#{Rails.root}/).join("\n\t"))
            CTS.error("(backtrace only includes project files, use --full-trace for everything)")
          elsif @options[:full_trace]
            CTS.error(e.backtrace.join("\n\t"))
          end
        end
        if error_count.positive?
          CTS.error("#{error_count} errors detected for case #{@case.number} id:#{@case.id}")
        end
      end
    end

    def check_upload_group_on_attachments(kase)
      kase.attachments.each do |attachment|
        raise "upload_group is nil for kase attachment #{attachment.key} id:#{attachment.id}" if attachment.upload_group.nil?
        raise "user_id is nil for kase attachment #{attachment.key} id:#{attachment.id}" if attachment.user_id.nil?
      end
    end

    def check_dacu_disclosure_assignment(kase)
      if kase.approving_teams.include?(CTS.dacu_disclosure_team) &&
          kase.responder.nil?
        raise "case is flagged for DACU Disclosure but has no responder assigned"
      end
    end

    def check_press_office_assignment(kase)
      if kase.approving_teams.include?(CTS.press_office_team) &&
          !kase.approving_teams.include?(CTS.dacu_disclosure_team)
        raise "case is flagged for Press Office but not DACU Disclosure"
      end
    end
  end
end
