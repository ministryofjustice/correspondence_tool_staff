require "rails_helper"

RSpec.describe Api::RpiController, type: :controller do
  let(:unencrypted_someone_else_json) do
    {
      "serviceSlug": "request-personal-information-migrate",
      "submissionId": "05e67905-c55a-4048-895a-6a76efe01f68",
      "submissionAnswers": {
        "requesting-own-data_radios_1": "Someone else's",
        "data-subject-name_text_1": "Andrew Pepler",
        "data-subject-name_text_2": "nickname",
        "subject-date-of-birth_date_1": "01 January 2000",
        "relationship-subject_radios_1": "Relative, friend or something else",
        "requestor-details_text_1": "friend full name",
        "personal-file-upload_multiupload_1": "address-(1).jpeg",
        "personal-address-upload_multiupload_1": "address-(2).jpeg",
        "letter-of-consent_multiupload_1": "address-(2).jpeg",
        "subject-photo-id_multiupload_1": "address-(3).jpeg",
        "subject-address-id_multiupload_1": "address-(4).jpeg",
        "personal-information-hmpps_radios_1": "Yes",
        "current-prison_radios_1": "Yes",
        "current-prison-name_text_1": "test",
        "subject-prison_text_1": "test",
        "prison-service-data_checkboxes_1": "NOMIS records; Security data; Something else",
        "prison-data-something-else_textarea_1": "asddas",
        "prison-dates_date_1": "01 January 2000",
        "prison-dates_date_2": "01 January 2000",
        "probation-information_radios_1": "Yes",
        "subject-probation_text_1": "asdasd",
        "probation_checkboxes_1": "Something else",
        "probation_textarea_1": "test",
        "probation-dates_date_1": "01 January 2010",
        "probation-dates_date_2": "01 February 2010",
        "laa-information_radios_1": "Yes",
        "laa_textarea_1": "asdds",
        "laa-dates_date_1": "03 March 2014",
        "laa-dates_date_2": "04 April 2014",
        "opg-information_radios_1": "Yes",
        "opg_textarea_1": "asd",
        "opg-dates_date_1": "05 May 2017",
        "opg-dates_date_2": "06 June 2017",
        "other-information_radios_1": "Yes",
        "what-other-information_textarea_1": "asdasd",
        "provide-somewhere-else-dates_date_1": "08 August 2019",
        "provide-somewhere-else-dates_date_2": "09 September 2019",
        "where-other-information_textarea_1": "asd",
        "contact-address_textarea_1": "asd",
        "contact-email_email_1": "asd@asd.com",
        "is-it-needed-for-court_radios_1": "Yes",
        "needed-for-court_textarea_1": "dssdfsdf",
      },
      "attachments": [
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/a8bd05f4-31dc-4aee-911a-3c997d8fb984?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHDXTQRUNP%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJHMEUCIQCO7dlxvvHx53bPOR2Ph5GY%2F9a%2BFf1lRRWnLUXVLBU02gIgBWh903rarunEiZ%2FxkLOqvU%2Brm0Mowq78Uht2i9f99pEquQUIGRAEGgw3NTQyNTY2MjE1ODIiDLliIrk7K1T%2BaRyZNiqWBfB4QxFUPH7f%2BkE6rifV2MDJeQJXqEt80zgwzgU19R0xkHWU%2BBkzJBOMaC2O%2B7BATrpbZpIsLgQfXsxGujpJnRSjdVxS4c3IoMdtdg%2FVynP1qN8CrLzPhbcrV6UejE3M2%2BoTKIWSuEHWGtPV3R8STA370X0ISNBnz0iyCdWbq3Tz%2Fwd3F9VL9VqaSYn4NUFMU07bS5toIuvUdjXq0f7849n1c8ZqRh8hWhpvhtDKYw5jjsFQ7iWuV1iKVlLSTow6wUVRpzCDh2Nm0WQSbdWY08Ufa3H%2Fls8G5lBqmcKQEJwPlrobbc3xFNuSeM1yMFboo7BftlYN%2FGk0d63ZMX9Kc3AVunO6ihx8Ew49%2FlpswcLLChQLd5fFXqkNuyiqdKcTYSEJzoGP22hTrP4Kyd7iQVBts%2Bvog2fLAr%2BE6ieW2VBXoCH1896hxJfJxHPOfMiZR4a5UW6t6v%2B6in%2BLSw4bWy6ZuWMNHeXEOl8o0KDonnsTEl348z69i8V9rgL%2FMR4W0oGr%2FreQTvtzJsMbDJF6kl5Z%2FXMP3sugoFbgMo4Ir1lS97EVRZb1ErKxKoT42oNvZuLMNZFobqHoFEvK%2BDZ5T1de%2FNi3Qqp5hB8M1CFhoI%2FdxJmA8Ah9sGueIKZ9OHMS%2FppuIQZzsiV31M742P6aTlFggNCINtklLZ2ihhrafWkOPNcSA3AGh2WL%2B86IwPKuJY1q6gkr39ko7UU6zokxhZ%2BOCjC3Czm4qCai%2BASIB%2F%2BWCFuVW2mlZR1vxffQdmbWClvnB8WqVEa9XrgjTgwMDdl%2BQBfPlEB08R2mylvcbDnPYoAvtND35Sv3eoh4pJR01NHrKcxvurSLBphZC6pItKChH7sR1mW0DD0I5OY1xm3U%2F4A4LqnKMJCYma4GOpsBiba8dd9nHTZnXbRQZ7w4pcs%2BKRNAldrWoA4zve30FkJNowXa%2BVHwRdOOFo8R1B%2B5vDm0yI5XtDb88Ht5NNA7Np3BocfTiUeZ52h61rYX%2FBLCbOJBICnkCSRkov%2FVZUMe8uyTuE039qexEtG2TL9UBg13NxMQ5CGHCjrukV%2BqoGcPhixLN9PZ9y01EmAj2dIlEFCqX4OLL5rw5mk%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=fbf3769868ee3ca3b7717849d7b02f27638b43bf6f10d93570f0426855ad926f",
          "encryption_key": "PbqbRUj+i2790jfEy9MpUTK71dh94sddaISoOKzr2Lo=",
          "encryption_iv": "mJAobyhJduOiuKlbEvrwLA==",
          "mimetype": "image/jpeg",
          "filename": "address-(1).jpeg",
        },
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/4b32f2b9-74aa-483f-ae64-924125b066ad?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHJHVBMIZ6%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJIMEYCIQD2rKJgRIHYxE3UClHRqkAp9uliXsIVgQ4eWRTJGKXJfAIhAIVfzAK7rstZIUl6UKtkrf3tvfLfbixvYQX0N8Ldz8LoKrkFCBkQBBoMNzU0MjU2NjIxNTgyIgwPjo4lqbsW8uuR2a0qlgWxkio63nng3Wv41kKlYYkkKZ2OZt2OCiLvyWzsDvCsmJMW9wWCkvgAX56tk5BCTT1ueqPASxqeWyHudnyf8KTQ9tDs5RXa%2Bo8j%2BYI64cm29VDO28CTmAAAuTiNJfBAODJjVNt6LKvpcr6NmeqCDp11ik8U7WoDXU4Ond5yur%2ByVMA6bA3UJWcMl3Xd8PE5Sszh9wzuOQL3H%2F2ePi%2BkBy6ojeGGyyYtB70TN1BQBuhdRfwynJW%2FGU2Fv%2BAnjbZrhZ6U5Ez96d3GVzv563WBmA3xFwt1ax5dcWmuRfsbYNda8L6xGRE80D9AiR6aRavv1R0DqA0T6GdJDNTCyxI2qKCkW1oF%2FgZ08RT1alUOm9Yy%2FuS5h8Au7ZLjpVrvDBk6DRbI7vrIrXtkK5FBZu7ACLZBPesk3EV8l4B2Wt2zfoKtEz7gEvwn2m9g3a1k9kOaxJtGlK1FdRj7%2B%2F3XiiaKB6JFBzLB9w%2BYi%2FWlYnDqgBBmrkV2GgBhtTFCAl5YuGNIcUg0ZVeE09ZylJp%2B0S%2FoPoaN3tbzsV0Zj9M72t%2BXaoEaQRg2wdoSzxO2kCGG50VERK86I1jw5ke9hcr7EZ08f%2FckA930K3RdPpATTqy27b%2FBNqUctUIDYXwgWczzlcmUjPDMOGzI2Bef%2F2Qz1bflhqtrfBfFd5%2FcRgYohY5JUaCil7BcaALeZyCN3CcmCUuH4WdyfoJOPAMD%2Bss%2FPwCa6vK2SiBkJfd7N3NaRLwbYOSEucOWj%2FWwsHc0lUr%2B0xj5b53w0n0WyiSZWU%2B1kskzlBq7K9BJDYCXd7Jnp4VIm2uNm70Eh7oXyd2L%2BDPNRWuY6NpAxyrGew3l%2FPLk%2FFPmS4i7ry4hAv9rlstAfVTVi3JtZe%2FZU%2BlgLDCQmJmuBjqaAdnVSY%2FvrjZ1woE3qe6txcBCLGetgZ0xq3ctVxRINDCfZpcvoW2mIKa3gTn%2Bfa0bLlzBKBj3DUIznczr%2BgPTTGU0yLdhuyFA8b%2FSuY2nZUNByf%2F2Z%2F0pUNbqenj64wiOdisj5uFmMl1OrP09swn%2BE581s6Uh9oVgPp5p5HAwb0vRk9U23cN1QZ3iqTqsgq6Mt5BrtC%2FMI62py%2F8%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=4881a8fb25daf50d2d19f925c96c8eef502b21b66b175411c6a229fa4011706b",
          "encryption_key": "q762Zh7oTb0N8IQfbVUrzL4P/d7RyKO5OKS0aQqMgcA=",
          "encryption_iv": "wYiO/y9YpsD3uwMsM74NEQ==",
          "mimetype": "image/jpeg",
          "filename": "address-(2).jpeg",
        },
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/62d21ce2-cd88-4a24-a317-78219d962ba3?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHHO36YVR4%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJHMEUCIB2P0mVkGcxCfQJuCQ79oZ%2Bcw3R1nfzR%2FVwKdgiJY3msAiEAmAG2phWH731cveMLnWCWE8hp3apbe%2FM68WI7hmD0bfYquQUIGRAEGgw3NTQyNTY2MjE1ODIiDDasvuQXmbB%2Fl6TUxCqWBYqOTIe1PnQRSlNv01uYesyT5B2A4ax2DL%2FI4J1UQ9DUJX1Or7ZjDacyiyCzL6HVBEZEzxtapFUeTC0z3lZhxzBsK2pd4E4CQrVFucDmDMlZ%2BQ8imaG9EeBhaOfONgkClImLYXIUrUgfGTOQP4wQa9lmhBdkddOzuJHdywy1Pm0IXnLc%2BgMCGc%2F%2BRDplVOhuUb%2Bw5esEj9cA3vJeIx%2Brd7a3BfEg%2FQ%2Bc%2F4BH%2BBLqUw%2BqCYeZa26BrFULAHpukCR6MM%2BtpamdbKnwhn5kp%2BY4U3nspiOkLKllNkWsQUKTZ3hbRBy3ANJvwNNyNQRuey1oaPJVte8oPTQwifB0JQSvxrib%2Fm%2BQWUsXM3%2FWa1hoWD2m8HdZCZA9oQDLjMuISLj11vX5q9i5vFkMgpORqoGK7Fjln%2BWlvXjnG%2FuEFBJwxLfsfLy9Houkvw%2FKAm%2FCEXOan02p8bVvyiWiCoPHu1M0fIu8W9xVSPxn04%2Bfv6D%2FudUKTkb7VH5gjTA8fdRZZ1p9nTqZO4wRb4skhgz3I6gmTBmtd7rA%2BDpcm3igQY8%2FepSbDJu2O%2FTxLcUuN9U4HF9YUrluQAkY%2BOCCt%2FdlnnljPtvE5Go7TgxsxPxvufc0nd86%2F5pl5%2BAAd7JD4G5WLZbbxDuoGEPYM1XlKXmhL7tpO6e1gOf4AEOEe8P0OJahCNpwVp5Aizsz4oAIOdR5fyefM9NXahHY2u%2FfTDkeL9XYh5ps%2BhN53Gz5NKz42%2B%2F9AV0KHfppb6lORGMQqza9pUUiaz1xNOyY1hsH1%2FkqEV7xPHXNoXWKh0ML6%2FO0Ab5hfxC0YHFcPI%2FqU7qaR2Xv3lBZSRloTXG1qFoGDB9d27OkYx91WzPL4w8PORpzQ%2BuMp5pvd39QWTSgMJCYma4GOpsBNeA6C4aVGyQr7WVcKcfvYKrMKr4FSL%2FN0Q8Z1purEeI9Ej6SMY7Dz%2F4E2RdefZ%2BkZC6bIvjB9Nw2qrjhPkRoVGa1W10JMk6TDPx5JF4TPDdWO0aGxK3nZFjBvFrhIqzqlbDVhbem0eU%2BK0DhxL9Jw%2F%2BPHbmfSgZJoyal%2FAHH33w3P8nbFUf96cpvyw209TgHaxgM3hIS0RuqNWY%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=ce47eeb78ed6c8e1088a7f16ffce4f7ca8b3a869e3879c4f66148759c9451530",
          "encryption_key": "iAIgLRK68p6VzAy4E1RtN4L/dNwBGDfEQM6xeSWq0zc=",
          "encryption_iv": "U0BJucYXvrZgH7l/TvZlJg==",
          "mimetype": "image/jpeg",
          "filename": "address-(2).jpeg",
        },
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/0f72d06a-e6ab-4370-bdf2-5e8e70210a31?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHHYYDWNTF%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJIMEYCIQCWYCGEF7ozyqn%2BYasqGaB3%2BKfml9%2BsAOBX1BH8Z8xa7gIhAKJJ77o7%2BIdQqolLOJNJOnRA6IyIS%2Bed76YsH8DKsJxfKrkFCBkQBBoMNzU0MjU2NjIxNTgyIgxRiYXR5V%2BME6TqF0sqlgW6XCcw6sIyd7%2BgwdmrdDxE1Sgg6EuHF6C7W9bWavZO3gokgIZoHnKN4TynQOVRwIg06%2FBBU4sD7Rq4fJBlP50iX2KToGulLFoyL0TTxb%2F6%2FzfHnmCxIpwONSbfMOWBhiQJe6ZdNFH0F8VL1vcCAZSFVwpML%2Fox2inNptL4sP4LNuu5LoLfT5WxH3plNeGstfVf4YYFy02t%2B%2BWaQYrswfFFATIjqEJF8yrbowsmw7MmcHfyOXClEsAtVMfFdfyXeVLXs5JfXIUd7sY0DQrKbmG%2B1OPcBbIDk0R7VXHjdQPy0q2KqSc4lRa5I4jhgwU1M%2B3Ce30Yq9IJgfJ22nGTRggeRmwDd6r%2BR5Ex0lalnw36nhcbvDx%2FxHnHqr%2BEUimc6OFEYjiVzkfBDLypOwcIPctJ%2FQqFaxp0WbhwFyNMFHuEXCuRbtw1rTjAY2JNZQmV%2FOa2TxgUGNd3QTNyBvmO%2F7AnOZet4NXO6DSip2XakDRbfre4TCOk7dFavCo6%2F9L8B78fcTd5CbxhypCR7hMvwNufrB7KOJs2UPg7ze2%2F7vVPc4bG14%2FM4uSmT9MOUSqQDD3Pg378NEvVuU0ZXEkJ2MDD8Rj8Q%2BQ7YVzFTmpV%2FUd7krgqar%2BhFFHo5YNfiLqc4xsuK4CJuOPsbrOAZJAoilYEMce8thlK5e6V7xz%2F3sENvXpk0F1SUIwsvmFw8S2EjAe5JN1XJNsx%2FY5wBrCJKqnM7SLfR60WLueJJUva9Ask4UTaYcboic6DUZBv2hE4S2aOEYP0S6kFcrVmtcAKA6UpMlGZ2F0%2F6eqSeIm%2BpIzfIxZatrYxPQPhxDnqWB6xpBTDAA8JGqxl4rYAcBrPHfBWgnPChQUnYh0kRIKJSIVsa%2BTHxkmkrDCQmJmuBjqaAUI2lW%2Bddp0KDfKj47SP28w%2FSShlkbFO4ACDKVpmxXFiUBUZcCmqUQj6hbq9vVzK2ZxrEiLqrShPjrqjqcc7%2B5XuC4PHfMnntiSSUQikYWw1LuHq2myvnqdR1%2Fr9u6yvu%2Be6OZQ5ykPa3VSr6nzRtrOzkhB%2B2%2FHL4Eacr9wEt8P5jHuRfGVMgPefUzNkVZkbRdYzS%2FuGKz0UJnE%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=1b432aa5210c5ec54ab20d0ac9eaef0a33c0e10c7104a1254f63abf80a658463",
          "encryption_key": "Kj6wcS6ex9et0JWNliC3JlHfeeFkcJSH0FP7QX3T+h0=",
          "encryption_iv": "2dTA8f98cZe6MB0VorW5UA==",
          "mimetype": "image/jpeg",
          "filename": "address-(3).jpeg",
        },
        {
          "url": "https://cloud-platform-3ddae276467a03ecb5ca598cfd99769b.s3.eu-west-2.amazonaws.com/59c8bfe5-15e9-4d43-9398-1afeb63e758e?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=ASIA27HJSWAHKUZSG2MB%2F20240209%2Feu-west-2%2Fs3%2Faws4_request&X-Amz-Date=20240209T160016Z&X-Amz-Expires=900&X-Amz-Security-Token=IQoJb3JpZ2luX2VjEEAaCWV1LXdlc3QtMiJIMEYCIQC6mHVWGj14aLxGhtVTMNW8%2BZwht%2By09ZhyMKEIB%2B0fxQIhAPxxFSPQkAD4DDQs3VQEReLNzxjxz0JX5yRIsl8WAiu7KrkFCBkQBBoMNzU0MjU2NjIxNTgyIgyTGxOIm4udlhmB0NYqlgWrT8ZVbBp2mzaAR9YR8O4B8s%2Bt7Q0Ksk7WyNpct01elVAyKLPiNIhtJtwEShVv66Ywl%2BsKZ41II4Fo2hVD%2BGMd5md3ez94OIYtxSedXD9sWijB47rTpvtF9L2uE4%2FfzbA1eEhdNVvuxwiMVxdLViLPCDmyqEo%2BEbVg82yE7wvaehsWYyaME%2FXR4eV0LAbMaeFNMypOVF%2Fu19X7l2v1IWJNLNAzD1ShivKiSJRNuq6mG2WfBeUV%2BAiLf4GMErBGynnsm2OKHlmcjCpyjEhW7X4i5YBrM3Lm%2BJs1xnDhsw%2BlkKwzriBkC9qosZgNIpzvgLUxCmER%2F81G7cqua%2BpYWbt9KfHrUXag4staTKpyK%2BthGtUgiiukC8KEKDDbodEaA4YTvea%2F7EEMfP7pSzlRB%2BdD026XBycrIJMGQhBCXB4EVU2ppfOClXeTyMcE12yuyVqQMS%2F5x9eYgS9k2Dd8SCaAeEQ1gAdzeFMM7NMpiJflJ2zwVcGs7yJ5Qw3SzXBpkufPgh8IzZwGCGR6Kdc6MQgX%2BH9pNV145B2EEGCkjeTTOAxEgJ9PLI1J%2B%2FsWBTlOnKQl8ImPNEmUtGfOZoxrjhL2Wmn%2BYtiVNMkAvbXI86ywUwnT3L4AyXhZJCFE9QpEfVq7Fy2AZfe%2FPFc2udIGq3IgbgFH59BkJZeOXbXSKgOzXnsgm6IFjh9UnQNjBDCUG7JIw8J%2F%2Bu%2Bj2vZX0emqKxoxEiEvYydfwa4ZajB1oWebYlstaY%2BZzsKSXKWNAYbEA3qrhb4Tyqq2ELFBgFpp3UH83mRqsr4UblCdQju4zV%2BQJ5UUhZA3erIJRNLScGj4rjTXSDFoVvlNVsaNv2j9hWtJNOFjYsw4MFBupRr9k5rqTtZRnaXDQDCQmJmuBjqaASiZpI7FTg2h%2BW5ncEIaYXspBBz%2BNISLbD2h7IiT%2B9SVxEcUDqP%2BnnhmiRLygLtB8Pr1H7S8q9EY%2Fw4sNPDHYGdSr9YW57lBDhrODs3LPycZ4QvvF7xJ%2BFQDeE%2BwzDgWIOq6NEKqWxsQP5rvSy9fQsRSWE6FFsU7RcCydsJjv%2FAVU0%2FKAHWF5kCPIGYixkQvtF4zCO6%2BKYX6vRE%3D&X-Amz-SignedHeaders=host&X-Amz-Signature=9ddd40cd655cc1856d0d7282a0bef1335849f931919603f00e50a33c0b16eb68",
          "encryption_key": "UH3F0fnC3xkU3oKLLqvOvIVIWjjudVE/v8Gtsm3QqBA=",
          "encryption_iv": "tDoBV6CNUHiHtOlYCokO8A==",
          "mimetype": "image/jpeg",
          "filename": "address-(4).jpeg",
        },
      ],
    }
  end

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

  let(:encrypted_json) { JWE.encrypt(unencrypted_json, Settings.rpi_jwe_key, alg: "dir") }

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
        post(:create, body: encrypted_json)
        expect(assigns(:decrypted_body)).to eq JSON.parse(unencrypted_json, symbolize_names: true)
      end
    end
  end

  describe "#create" do
    it "attempts to send an email" do
      expect(ActionNotificationsMailer).to receive(:rpi_email).with(RequestPersonalInformation).and_call_original
      post(:create, body: encrypted_json)
    end
  end
end
