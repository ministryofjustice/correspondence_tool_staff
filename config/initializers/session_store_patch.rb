# Patch for activerecord-session_store 2.2.0: a cookie containing non-UTF-8
# bytes (e.g. a corrupted or binary session token) causes `private_session_id?`
# to raise ArgumentError when the regex engine validates encoding. Using the /n
# (no-encoding / binary) flag bypasses the UTF-8 check so the regex runs safely
# against any byte sequence.
module ActionDispatch
  module Session
    class ActiveRecordStore
      def self.private_session_id?(session_id)
        session_id =~ /\A\d+::/n
      end
    end
  end
end