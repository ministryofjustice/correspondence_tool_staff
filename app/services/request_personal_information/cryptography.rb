class RequestPersonalInformation::Cryptography
  def initialize(encryption_key:, encryption_iv:)
    validate_key_iv!(encryption_key, encryption_iv)

    @encryption_key = encryption_key
    @encryption_iv = encryption_iv
  end

  def encrypt(file:)
    cipher.encrypt
    cipher.iv = encryption_iv
    cipher.key = encryption_key
    encrypted_data = cipher.update(file) + cipher.final # rubocop:disable Rails/SaveBang
    encrypted_data.unpack1("H*")
  end

  def decrypt(file:)
    data =
      if file.is_a?(String)
        if file =~ /\A[\da-fA-F]+\z/
          [file].pack("H*") # hex-encoded string
        else
          file.b # treat as raw text, convert to binary
        end
      else
        file
      end

    cipher.decrypt
    cipher.iv = encryption_iv
    cipher.key = encryption_key

    cipher.update(data) + cipher.final # rubocop:disable Rails/SaveBang
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new "AES-256-CBC"
  end

private

  attr_accessor :encryption_key, :encryption_iv

  # rubocop:disable Naming/MethodParameterName
  def validate_key_iv!(key, iv)
    unless key.is_a?(String) && key.bytesize == 32
      raise ArgumentError, "Encryption key must be a 32-byte string for AES-256-CBC"
    end

    unless iv.is_a?(String) && iv.bytesize == 16
      raise ArgumentError, "Encryption IV must be a 16-byte string for AES-256-CBC"
    end
  end
  # rubocop:enable Naming/MethodParameterName
end
