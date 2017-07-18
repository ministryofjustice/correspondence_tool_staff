module CTS
  class Cases
    class Check
      def initialize(kase_id_or_number, options)
        @case = CTS::find_case(kase_id_or_number)
        @options = options
      end

      def call
        check_methods = public_methods.grep(/^check_/)
        check_methods.each do |check_method|
          begin
            self.__send__(check_method, @case)
          rescue => err
            CTS::error("check '#{check_method}' failed for case #{@case.number} id:#{@case.id}")
            CTS::error(err.message)
            if @options[:full_trace]
              CTS::error(err.backtrace.join("\n\t"))
            else
              CTS::error(err.backtrace.grep(/#{Rails.root}/).join("\n\t"))
              CTS::error("(backtrace only includes project files, user --full-trace for everything)")
            end
          end
        end
      end

      def check_upload_group_on_attachments(kase)
        kase.attachments.each do |attachment|
          raise "upload_group is nil for kase attachment #{attachment.key} id:#{attachment.id}" if attachment.upload_group.nil?
          raise "user_id is nil for kase attachment #{attachment.key} id:#{attachment.id}" if attachment.user_id.nil?
        end
      end
    end
  end
end
