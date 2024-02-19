require "rails_helper"

describe RequestPersonalInformation::Cryptography do
  let(:encryption_key) { "a9c12000de36def805e4c2107bd8e910" }
  let(:encryption_iv) { "1234567890123451" }
  let(:cryptography) do
    described_class.new(
      encryption_key:,
      encryption_iv:,
    )
  end

  describe "#encrypt" do
    let(:file) { Rails.root.join("spec/fixtures/hello.txt").read }
    let(:encrypted_data) { cryptography.encrypt(file:) }
    let(:data) { "7fe1e0ae21bfd938156d6b199c8d900f" }

    it "changes the file content using AES-256 encryption" do
      expect(encrypted_data).to eq(data)
    end
  end

  describe "#decrypt" do
    let(:plain_text_file_data) { Rails.root.join("spec/fixtures/hello.txt").read }
    let(:encrypted_file_data) { "7fe1e0ae21bfd938156d6b199c8d900f" }
    let(:decrypted_file_data) { cryptography.decrypt(file: encrypted_file_data) }

    it "converts encrypted data back to plain text" do
      expect(decrypted_file_data).to eq(plain_text_file_data)
    end
  end
end
