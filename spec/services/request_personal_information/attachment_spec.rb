require "rails_helper"

describe RequestPersonalInformation::Attachment do
  subject(:attachment) { described_class.new(payload) }

  let(:payload) do
    {
      "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/a8bd05f4-31dc-4aee-911a-3c997d8fb984?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHDXTQRUNP%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJHMEUCIQCO7dlxvvHx53bPOR2Ph5GY%2F9a%2BFf1lRRWnLUXVLBU02gIgBWh903rarunEiZ%2FxkLOqvU%2Brm0Mowq78Uht2i9f99pEquQUIGRAEGgw3NTQyNTY2MjE1ODIiDLliIrk7K1T%2BaRyZNiqWBfB4QxFUPH7f%2BkE6rifV2MDJeQJXqEt80zgwzgU19R0xkHWU%2BBkzJBOMaC2O%2B7BATrpbZpIsLgQfXsxGujpJnRSjdVxS4c3IoMdtdg%2FVynP1qN8CrLzPhbcrV6UejE3M2%2BoTKIWSuEHWGtPV3R8STA370X0ISNBnz0iyCdWbq3Tz%2Fwd3F9VL9VqaSYn4NUFMU07bS5toIuvUdjXq0f7849n1c8ZqRh8hWhpvhtDKYw5jjsFQ7iWuV1iKVlLSTow6wUVRpzCDh2Nm0WQSbdWY08Ufa3H%2Fls8G5lBqmcKQEJwPlrobbc3xFNuSeM1yMFboo7BftlYN%2FGk0d63ZMX9Kc3AVunO6ihx8Ew49%2FlpswcLLChQLd5fFXqkNuyiqdKcTYSEJzoGP22hTrP4Kyd7iQVBts%2Bvog2fLAr%2BE6ieW2VBXoCH1896hxJfJxHPOfMiZR4a5UW6t6v%2B6in%2BLSw4bWy6ZuWMNHeXEOl8o0KDonnsTEl348z69i8V9rgL%2FMR4W0oGr%2FreQTvtzJsMbDJF6kl5Z%2FXMP3sugoFbgMo4Ir1lS97EVRZb1ErKxKoT42oNvZuLMNZFobqHoFEvK%2BDZ5T1de%2FNi3Qqp5hB8M1CFhoI%2FdxJmA8Ah9sGueIKZ9OHMS%2FppuIQZzsiV31M742P6aTlFggNCINtklLZ2ihhrafWkOPNcSA3AGh2WL%2B86IwPKuJY1q6gkr39ko7UU6zokxhZ%2BOCjC3Czm4qCai%2BASIB%2F%2BWCFuVW2mlZR1vxffQdmbWClvnB8WqVEa9XrgjTgwMDdl%2BQBfPlEB08R2mylvcbDnPYoAvtND35Sv3eoh4pJR01NHrKcxvurSLBphZC6pItKChH7sR1mW0DD0I5OY1xm3U%2F4A4LqnKMJCYma4GOpsBiba8dd9nHTZnXbRQZ7w4pcs%2BKRNAldrWoA4zve30FkJNowXa%2BVHwRdOOFo8R1B%2B5vDm0yI5XtDb88Ht5NNA7Np3BocfTiUeZ52h61rYX%2FBLCbOJBICnkCSRkov%2FVZUMe8uyTuE039qexEtG2TL9UBg13NxMQ5CGHCjrukV%2BqoGcPhixLN9PZ9y01EmAj2dIlEFCqX4OLL5rw5mk%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=fbf3769868ee3ca3b7717849d7b02f27638b43bf6f10d93570f0426855ad926f",
      "encryption_key": "PbqbRUj+i2790jfEy9MpUTK71dh94sddaISoOKzr2Lo=",
      "encryption_iv": "mJAobyhJduOiuKlbEvrwLA==",
      "mimetype": "image/jpeg",
      "filename": "address-(1).jpeg",
    }
  end

  let(:payload_unencrypted) do
    {
      "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/a8bd05f4-31dc-4aee-911a-3c997d8fb984?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHDXTQRUNP%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJHMEUCIQCO7dlxvvHx53bPOR2Ph5GY%2F9a%2BFf1lRRWnLUXVLBU02gIgBWh903rarunEiZ%2FxkLOqvU%2Brm0Mowq78Uht2i9f99pEquQUIGRAEGgw3NTQyNTY2MjE1ODIiDLliIrk7K1T%2BaRyZNiqWBfB4QxFUPH7f%2BkE6rifV2MDJeQJXqEt80zgwzgU19R0xkHWU%2BBkzJBOMaC2O%2B7BATrpbZpIsLgQfXsxGujpJnRSjdVxS4c3IoMdtdg%2FVynP1qN8CrLzPhbcrV6UejE3M2%2BoTKIWSuEHWGtPV3R8STA370X0ISNBnz0iyCdWbq3Tz%2Fwd3F9VL9VqaSYn4NUFMU07bS5toIuvUdjXq0f7849n1c8ZqRh8hWhpvhtDKYw5jjsFQ7iWuV1iKVlLSTow6wUVRpzCDh2Nm0WQSbdWY08Ufa3H%2Fls8G5lBqmcKQEJwPlrobbc3xFNuSeM1yMFboo7BftlYN%2FGk0d63ZMX9Kc3AVunO6ihx8Ew49%2FlpswcLLChQLd5fFXqkNuyiqdKcTYSEJzoGP22hTrP4Kyd7iQVBts%2Bvog2fLAr%2BE6ieW2VBXoCH1896hxJfJxHPOfMiZR4a5UW6t6v%2B6in%2BLSw4bWy6ZuWMNHeXEOl8o0KDonnsTEl348z69i8V9rgL%2FMR4W0oGr%2FreQTvtzJsMbDJF6kl5Z%2FXMP3sugoFbgMo4Ir1lS97EVRZb1ErKxKoT42oNvZuLMNZFobqHoFEvK%2BDZ5T1de%2FNi3Qqp5hB8M1CFhoI%2FdxJmA8Ah9sGueIKZ9OHMS%2FppuIQZzsiV31M742P6aTlFggNCINtklLZ2ihhrafWkOPNcSA3AGh2WL%2B86IwPKuJY1q6gkr39ko7UU6zokxhZ%2BOCjC3Czm4qCai%2BASIB%2F%2BWCFuVW2mlZR1vxffQdmbWClvnB8WqVEa9XrgjTgwMDdl%2BQBfPlEB08R2mylvcbDnPYoAvtND35Sv3eoh4pJR01NHrKcxvurSLBphZC6pItKChH7sR1mW0DD0I5OY1xm3U%2F4A4LqnKMJCYma4GOpsBiba8dd9nHTZnXbRQZ7w4pcs%2BKRNAldrWoA4zve30FkJNowXa%2BVHwRdOOFo8R1B%2B5vDm0yI5XtDb88Ht5NNA7Np3BocfTiUeZ52h61rYX%2FBLCbOJBICnkCSRkov%2FVZUMe8uyTuE039qexEtG2TL9UBg13NxMQ5CGHCjrukV%2BqoGcPhixLN9PZ9y01EmAj2dIlEFCqX4OLL5rw5mk%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=fbf3769868ee3ca3b7717849d7b02f27638b43bf6f10d93570f0426855ad926f",
      "filename": "address-(1).jpeg",
    }
  end

  describe "#file_data" do
    let(:file) { "file body" }
    let(:file_retriever) { double("connection", body: file) } # rubocop:disable RSpec/VerifiedDoubles

    context "when file is encrypted" do
      let(:crypt_obj) { instance_double(RequestPersonalInformation::Cryptography) }

      it "passes attachment details to a cryptography object" do
        allow(RequestPersonalInformation::Cryptography).to receive(:new).with(
          encryption_key: Base64.strict_decode64("PbqbRUj+i2790jfEy9MpUTK71dh94sddaISoOKzr2Lo="),
          encryption_iv: Base64.strict_decode64("mJAobyhJduOiuKlbEvrwLA=="),
        ).and_return(crypt_obj)

        allow(HTTParty).to receive(:get).and_return(file_retriever)
        expect(crypt_obj).to receive(:decrypt).with(file:)

        attachment.file_data
      end
    end

    context "when file is not encrypted" do
      subject(:attachment) { described_class.new(payload_unencrypted) }

      it "downloads file" do
        allow(HTTParty).to receive(:get).and_return(file_retriever)

        expect(attachment.file_data).to eq file
      end
    end
  end

  describe "#filename" do
    it "gets the filename from the payload" do
      expect(attachment.filename).to eq "address-(1).jpeg"
    end
  end
end
