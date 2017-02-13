# Correspondence Tools - Staff
[![Build Status](https://travis-ci.org/ministryofjustice/correspondence_tool_staff.svg?branch=develop)]
(https://travis-ci.org/ministryofjustice/correspondence_tool_staff) 
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)]
(https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage) [![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)


A simple application to allow internal staff users to answer correspondence. 

##Local development

###Clone this repository change to the new directory

```bash
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

###Rake Tasks 

Last two rake demo tasks are not required for production service.
 
```
$ rails db:create
$ rails db:migrate
$ rails db:seed
$ rails users:demo_entries
$ rails correspondence:demo_entries
```

### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.
In local development, uploads are place in the
[correspondence-staff-case-uploads-testing](https://s3-eu-west-1.amazonaws.com/correspondence-staff-case-uploads-testing/)
bucket.

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

If you have an MoJ account in AWS IAM, you can configure the aws-sdk with your access and secret key by placing them in the `[default]` section in `.aws/credentials`:

1. [Retrieve you keys from your IAM account](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)<sup>[1](#user-content-footnote-aws-access-key)</sup> if you don't have them already.
2. [Place them in `~/.aws/credentals`](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html)

#### Using shared credentials

Alternatively, if you don't have an AWS account with access to that bucket, you
can get access by using an access and secret key specifically generated for
testing:

1. Retrieve the 'Case Testing Uploads S3 Bucket' key from the Correspondence
   group in Rattic.
2. [Use environment variables to configure the AWS SDK](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment)
   locally.



# Footnotes

<a name="footnote-aws-access-key">1</a>: When following these instructions, I had to replace step 3 (Continue to Security Credentials) with clicking on *Users* on the left, selecting my account from the list there, and then clicking on "Security Credentials".
