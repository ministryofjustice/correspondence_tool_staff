require "rails_helper"

RSpec.describe Api::RpiController, type: :controller do
  let(:unencrypted_json) do
    {
      "serviceSlug": "request-personal-information-migrate",
      "submissionId": "0fc67a0a-1c58-48ee-baec-36f9f2aaebe3",
      "submissionAnswers": {
        "requesting-own-data_radios_1": "Your own",
        "request-personal-data_text_1": "Andrew Pepler",
        "request-personal-data_text_2": "nickname",
        "personal-dob_date_1": "14 August 1978",
        "personal-file-upload_multiupload_1": "blue.jpeg",
        "personal-address-upload_multiupload_1": "address.jpeg",
        "personal-information-hmpps_radios_1": "Yes",
        "mine-prison_text_1": "answer to What was your prison number? (optional)",
        "mine-recent-prison_text_1": "answer to Which prison were you most recently in?",
        "prison-service-data_checkboxes_1": "NOMIS records; Security data; Something else",
        "prison-data-something-else_textarea_1": "ansewr to What other prison service information do you want?",
        "prison-dates_date_1": "01 January 2000",
        "prison-dates_date_2": "02 February 2000",
        "probation-information_radios_1": "Yes",
        "mine-probation_text_1": "Answer to Where is your probation office or approved premises?",
        "probation_checkboxes_1": "nDelius file; Something else",
        "probation_textarea_1": "answer to If you selected something else, can you provide more detail?",
        "probation-dates_date_1": "01 January 2001",
        "probation-dates_date_2": "02 February 2001",
        "laa-information_radios_1": "Yes",
        "laa_textarea_1": "answer to What information do you want from the Legal Aid Agency (LAA)?",
        "laa-dates_date_1": "01 January 2002",
        "laa-dates_date_2": "02 February 2002",
        "opg-information_radios_1": "Yes",
        "opg_textarea_1": "answer to What information do you want from the Office of the Public Guardian (OPG)?",
        "opg-dates_date_1": "01 January 2003",
        "opg-dates_date_2": "02 February 2003",
        "other-information_radios_1": "Yes",
        "what-other-information_textarea_1": "answer to What information do you want from somewhere else in the Ministry of Justice?",
        "provide-somewhere-else-dates_date_1": "01 January 2004",
        "provide-somewhere-else-dates_date_2": "02 February 2004",
        "where-other-information_textarea_1": "answer to Where in the Ministry of Justice do you think this information is held?",
        "contact-address_textarea_1": "answer to Where we'll send the information",
        "contact-email_email_1": "user@email.com",
        "is-it-needed-for-court_radios_1": "Yes",
        "needed-for-court_textarea_1": "answer to Tell us more about your upcoming court case or hearing",
      },
      "attachments": [
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/5222a10d-c2cb-4f11-b7a9-5883c67ecf2b?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHJOTI4UG5%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T111332Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEDwaCWV1LXdlc3QtMiJGMEQCIBCSNACJuPr65wNpF1jcCwQdzOzbv8s4tUSNFI30K%2FN7AiAdnPdv1SsAHC2awgLtHzK6f5rhIkpjcAGNDyfHUcEFniq5BQgUEAQaDDc1NDI1NjYyMTU4MiIMvln8sX1uuBjg9QN%2BKpYFjvH3EnCBYHLb9mP5RUw2%2FlvrzkGRQg6ajvRhL4nAi%2FoOI%2FybwxQGgK4vkIYfsZZZc8hPT5Mb2%2Fg4js%2BSYnYoQSXmsWdUYv7vQ1YEJE6kpFncgq%2BpaEacfBNLNS1F7nQF69UImweq7Eg%2BWMqEeuX3eiJ%2BnlZs7X1zp4fKXD4ayvU410pNf%2FTScZmKWWdWA8ve92p72st0OzZXBDjEBcyxcnt58%2F%2BTgxnswcGzgnFEhv7ZvzXhk7HlEm0pO4nILhqaILpFcGu5QkoXrRASI9J9dUfEjoqSb2H3Sa4fr%2FIjC7sLSwx0C1JZG339uQHb0NdINMPwlC3wf%2FDMp25ApaCUamXslN8r9hZwOesY%2BTxkzm2pBinp3DpzXUT5E3cD7pc2URSJCnwa9KFfL%2FqhiRN81V7vR%2BjnLxPkR0R3KSRLsHPAjdav9YJIeIvGAhZ7FO3qX2aevFYsU%2F2zexBL8QU9MgYTc7tCyPaeOIlrZw0dvv8bca45hm3WO%2FT2le0VznvdxCo1ozA3Bj%2BaLdqnJOLEAqS97UBmVfyrhGXqvsMXwbFIMMmcS%2BU61CcHuxqqfQ5EpYNGZaIqVoRmv3XYK7zbJmDq5qPxPJH%2F9tBGbnBR083jRh1pOA60tvwm7WayC0tcdCkUbtQvISa7%2FolW9Tk8jeMtoDzqQziMH%2BYFCz%2FDEoXpji55ipP8HIOD0e1SIdvOrgpHW4CxDL3vsfcGeBKSXroNjSEB2fCyzw%2FfZO2F6MqL0GDg1heZTsLknRR4xrmZ9%2BaYJnXB%2FcEYdY9Gj%2B%2FILTTjtG%2FXGeSbe4aw%2Fhh01qU1Lx%2Bsn2OV4j7uH8vMo8o%2B%2BvJ%2BhKgJYTHGF7aKKthrl6L%2Bs8WRPnlfpWZ4Bd%2Bn8aMRufp4JYww25GYrgY6nAH3HslWjbhUY5caoCabKI%2Fg%2BIErQps2SggczUWMP%2BXTMIzXpaifhpCj9ZNEsRlFex1n0U%2F%2BXr8FYXILFERMdSB3MPMJdbGMJY%2FlOFXXRh9MSBkT1jqlm%2F9IV7UI1aQ1idAsISSYnx0OXr88OtJV%2Bwgbsa0ikmhD2DLK5VXNZ00vi9vyf4BtEDUvz4obhIhN2%2FHlUc34PwHXeyMaO1A%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=446ac6e74d7f1fae7b50b40993cdaaed6d68c96da9032d9159df6a8f914c0f74",
          "encryption_key": "SmAKf+rBBJgxfrqYS4FCPsdoimZqHArjAsbrOeQiV/Q=",
          "encryption_iv": "Axr0dAjrT576IpAvto4W6A==",
          "mimetype": "image/jpeg",
          "filename": "blue.jpeg",
        },
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/97df4cc9-6878-4536-8326-7973f9862486?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHLKD7SPUE%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T111332Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEDwaCWV1LXdlc3QtMiJHMEUCIA%2FiK6yucHazCGTAeDwxWXElZT4JDmhd0YUYZKUlg7bYAiEAmrFRlT%2BVUb%2BUFVb0Bf6XK8kn4GLFtGkzh%2BXox3fTL%2BkquQUIFBAEGgw3NTQyNTY2MjE1ODIiDOZcrsI5HPrYBmzPdCqWBYlcslZaGSV%2BBlfnd4UpPQpxdavxLMOsaYZCEqfbIPtCO6BcMWSetPS%2F5jVfc6tbxQ3suezMB4UR%2F0k8SjlavYVEgJnTcKimI7N0AvGIrGLdZ7YLR7XelgUfdKqgeclQVSWgFFkWOstUvEE9602s8Z%2F5a%2B4zXB9MQF6vXvMkJz7L95RVBuxzHh96g9vFJWU4NGQZQFGsAfT1naxB%2Beoh4JnIcs4JN6OfTc0GPVI7umsxU3%2FhE%2BAOCOWErgwets1fbc5vIH%2B3e6ym752YtWh7DynJTk5O15CyKY0Xklx06AT1HDqoz0l6goN93UkuruW7oMEAckBZxGB4iuU0%2BloEjeTqToZ7DTwrzE9v2FMsVPpodXVxI6POeQ8AZ2GzsKRJGg6mpTrdp2h7XbHaI9INRntRlfBNfv2StP6ZJ1rDyVGB0rR3X2V2p2akFXTnTToKek8GK03bmgoYtZrwiAkDMozkeXfsSCUPwdySJYKUpzchy0s1l2KnOmSpXtafGpzMfvOQEIgS3oyyW4wyi7vsDZoeezbT0B7lQR5IaAE1kUAIjxBog%2FNo0h3y578P2WkuHpCiHV50so4X7Cx5T81jW2AJ0soWlhq2yFaYdReMFd%2FyqH5X40DohLetTx24cDU1hCYA6cT3nSUc%2Bkwa4NIRra3piCs%2F2s1ZCxRwbrC%2Fo2rfajBoDbPFZ4fHs%2FiIjj5skuN%2B9khPvSEXseKkfsSjBIXYVA%2F9DxKTDpjz3O%2FjZy4BMuQLk8thVD%2B5qrJF5TXNnhyJrNSP27ZqmaH3pTHUPjsbHTyAWT9YsKbmwyPswz%2BUxBWhM%2BFcodUq3HiM4SKNA1vBlNvedzcwUNWzWBIWSG2ZCxdwb%2FGb9atP61%2BQzLsXKDr2%2F2mzMNyRmK4GOpsBPG8P8%2FoCVjoeyJ9zvLqUUqPTHjT2oHYAWmgeDIRKU7ipiN2P5btiAHuhnXqbZn9dboWiwo5vfqytA09RF%2B74cl0iaV%2BMbF%2F3qHwuKaTZO%2BuZf0OM%2BIfKI1J4FHK7WOY3IMbfGdgxWRc0T%2BHoe5gH%2FNsdX0Lys7GKViHbdlJGvYXJ3E6wKlu%2BloMx%2BnTBWL%2FmzBKr8aNqFUngLLI%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=5aac1924e77d64a7baa0a77cd1710143cfa1e5f553679f8a107e876e3add16f5",
          "encryption_key": "LGR3zmjNWM1/ZQ7oMrVRYgGoS1CMRA7A0xcy7PMFKbI=",
          "encryption_iv": "YDPz/zLSGWzB0pM2VDgjjw==",
          "mimetype": "image/jpeg",
          "filename": "address.jpeg",
        },
      ],
    }.to_json
  end

  let(:invalid_json_body) do
    {
      invalid: "json",
    }.to_json
  end

  describe "authenticates the request" do
    context "with no body" do
      it "responds with 401" do
        post(:create)
        expect(response.status).to eq 401
      end
    end

    context "with invalid data" do
      it "responds with 401" do
        post(:create, body: invalid_json_body)
        expect(response.status).to eq 401
      end
    end

    context "with encrypted json payload" do
      it "decrypts the body" do
        encrypted_json = JWE.encrypt(unencrypted_json, Settings.rpi_jwe_key, alg: "dir")
        post(:create, body: encrypted_json)
        expect(assigns(:decrypted_body)).to eq JSON.parse(unencrypted_json, symbolize_names: true)
      end
    end
  end
end
