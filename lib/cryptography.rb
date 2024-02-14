class Cryptography
  def initialize(encryption_key:, encryption_iv:)
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
    cipher.decrypt
    cipher.iv = encryption_iv
    cipher.key = encryption_key
    data = [file].pack("H*").unpack("C*").pack("c*")
    cipher.update(data) + cipher.final # rubocop:disable Rails/SaveBang
  end

  def cipher
    @cipher ||= OpenSSL::Cipher.new "AES-256-CBC"
  end

private

  attr_accessor :encryption_key, :encryption_iv
end
