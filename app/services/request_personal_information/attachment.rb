class RequestPersonalInformation::Attachment
  def initialize(data)
    @data = data
  end

  def file_data
    RequestPersonalInformation::Cryptography.new(
      encryption_key: Base64.strict_decode64(encryption_key),
      encryption_iv: Base64.strict_decode64(encryption_iv),
    ).decrypt(file: HTTParty.get(url).body)
  end

  def filename
    @data[:filename]
  end

private

  def url
    @data[:url]
  end

  def encryption_key
    @data[:encryption_key]
  end

  def encryption_iv
    @data[:encryption_iv]
  end
end
