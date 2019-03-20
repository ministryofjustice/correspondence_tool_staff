# Correspondence Tools - Staff
[![Build Status](https://travis-ci.org/ministryofjustice/correspondence_tool_staff.svg?branch=develop)](https://travis-ci.org/ministryofjustice/correspondence_tool_staff)
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage)
[![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Build Status](https://semaphoreci.com/api/v1/aliuk2012/correspondence_tool_staff/branches/master/badge.svg)](https://semaphoreci.com/aliuk2012/correspondence_tool_staff)


A simple application to allow internal staff users to answer correspondence.

## Development

### Working on the Code

Work should be based off of, and PRed to, the master branch. We use the GitHub
PR approval process so once your PR is ready you'll need to have one person
approve it, and the CI tests passing, before it can be merged. Feel free to use
the issue tags on your PR to indicate if it is a WIP or if it is ready for
reviewing.


### Basic Setup

#### Cloning This Repository

Clone this repository then `cd` into the new directory

```
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

#### Generating Documentation

You can generate documentation for the project with:

```
bundle exec yardoc
```

If you need to you can edit settings for Yard in `Rakefile`. The documentation
is generated in the `doc` folder, to view it on OSX run:

```
open doc/index.html
```

### Installing the app for development

You can either install the app in a docker container, or set it up natively on your mac.  Instructions for both methods are given below.

#### Installing the app in a Docker container

Install [Docker for Mac](https://docs.docker.com/docker-for-mac/) and then run this in the
repository directory:

```
$ docker-compose up
```

This will build and run all the Docker containers locally and publish port 3000
from the web container locally. The application will be available on
http://localhost:3000/


##### Editing source
You can edit the source files directly on your local machine - the repository directory is shared with the docker container.

##### Logs
Messages to the logs behave slightly differently than expected:

* Any `puts` commands in the code will be output to the `docker-compose` window, but not to the `log/development.log` file.
* Any `Rails.logger.info|error|warn|debug` commands in the code will be output to the `log/development.log` file and NOT to the `docker-compose` window.
* The `docker-compose logs` command on the host machine will display the same output as for the `docker-compose` window.



### Installing locally on a mac

#### Installing Dependencies

If you want to run the app natively on your mac, follow these instructions to install dependencies.

<details>
<summary>Installing Postgres 9.5.x</summary>

We use version 9.5.x of PostgreSQL to match what we have in the deployed
environments. Also, because the `structure.sql` file generated by PostgreSQL
can change with every different version postgres, all developers on the project
should use the same version to prevent minor changes to the structure file on each commit.

There are two options for installing postgres:

* **The Postgres OS X application**
	* Download the Postgres application from the App Store
	* Start the app, click the plus sign bottom left, and add a new server, specifying 9.5.
* **The Homebrew postgres 9.5 package**
	Install the specific 9.5 version with homebrew

```
$ brew install postgresql@9.5
```

Having done this, make sure all the post-install variables have been put in
`.bash_profile` or similar e.g.

export PKG_CONFIG_PATH="/usr/local/opt/postgresql@9.5/lib/pkgconfig"
export CPPFLAGS="-I/usr/local/opt/postgresql@9.5/include"
export LDFLAGS="-L/usr/local/opt/postgresql@9.5/lib"
export PATH=$PATH:/usr/local/opt/postgresql@9.5/bin

The PKG_CONFIG_PATH and PATH are useful to help install the PG gem
</details>

<details>
<summary>Latest Version of Ruby</summary>

If you don't have `rbenv` already installed, install it as follows:
```
brew install rbenv
rbenv init
```

Use `rbenv` to install the latest version of ruby as defined in `.ruby-version` (make sure you are in the repo path):

```
$ rbenv install
$ rbenv init
$ rbenv rehash
```
Follow the instructions printed out from the `rbenv init` command and update your `~/.bash_profile` file accordingly, then start a new terminal and navigate to the repo directory.

```
$ gem install bundler
```

</details>

<details>
<summary>Installing Latest XCode Stand-Alone Command-Line Tools</summary>

May be necessary to ensure that libraries are available for gems, for example
Nokogiri can have problems with `libiconv` and `libxml`.

```
$ xcode-select --install
```
</details>

#### Issues installing PostgreSQL (pg) gem

When running `bundle install` on MacOS `gem pg` may fail to build and install.

(These issues may not occur if following the instructions above about setting the PKG_CONFIG_PATH)

##### Error with missing libpq-fe.h
```
...
No pg_config... trying anyway. If building fails, please try again with
 --with-pg-config=/path/to/pg_config
checking for libpq-fe.h... no
Can't find the 'libpq-fe.h header
*** extconf.rb failed ***
Could not create Makefile due to some reason, probably lack of necessary
libraries and/or headers.  Check the mkmf.log file for more details.  You may
need configuration options.
...
```

Assuming the installation steps have been followed, execute in Terminal:

```
export CONFIGURE_ARGS="with-pg-include=/usr/local/opt/postgresql@9.5/include";
gem install pg -v '1.1.4' --source 'https://rubygems.org/';

```
And ensure you add the following to `.bash_profile` or similar to prevent TCP connection errors:

```
export PGHOST=localhost
```

<details>
<summary>Installing Redis</summary>

Redis is needed to run the 'db:reseed' task. Redis is used as the adapted for
delayed jobs in the system.

```
brew install redis
```
</details>

<details>
<summary>Testing</summary>

This project can produce code coverage data (w/o JS or views) using the `simplecov` gem
set COVERAGE=1 (or any value) to generate a coverage report.
Parallel tests are supposed to be supported - however the coverage output from simplecov is a little
strange (the total lines in the project are different for each coverage run)

This project includes the `parallel_tests` gem which enables multiple CPUs to be used during testing
in order to speed up execution. Otherwise running the tests takes an unacceptably long amount of time.

The default parallelism is 8 (override by setting PARALLEL_TEST_PROCESSORS) which seems to be about
right for a typical Macbook Pro (10,1 single processor with 4 cores)

##### To set up parallel testing

1. Create the required number of extra test databases:

```
rails parallel:create
```

2. Load the schema into all of the extra test databases:

```
rails parallel:load_structure
```

###### To run all the tests in parallel

```
rails parallel:spec
```

###### To run only feature tests in parallel

```
rails parallel:spec:features
```

###### To run only the non-feature tests in parallel

```
rails parallel:spec:non_features
```
</details>

<details>
<summary>Browser testing</summary>

We use [headless chrome](https://developers.google.com/web/updates/2017/04/headless-chrome)
for Capybara tests, which require JavaScript. You will need to install Chrome >= 59.
Where we don't require JavaScript to test a feature we use Capybara's default driver
[RackTest](https://github.com/teamcapybara/capybara#racktest) which is ruby based
and much faster as it does not require a server to be started.

**Debugging:**

To debug a spec that requires JavaScript, you need to set a environment variable called CHROME_DEBUG.
It can be set to any value you like.

Examples:

```
$ CHROME_DEBUG=1 bundle exec rspec
```

When you have set `CHROME_DEBUG`, you should notice chrome start up and appear on your
taskbar/Docker. You can now click on chrome and watch it run through your tests.
If you have a `binding.pry`  in your tests the browser will stop at that point.
</details>

#### Database Setup

Run these rake tasks to prepare the database for local development.

```
$ rails db:create
$ rails db:reseed
```

The `db:reseed` rake task will:
 - clear the database  by dropping all the tables and enum types
 - load the structure.sql
 - run all the data migrations

This will have the effect of setting up a standard set of teams, users, reports, correspondence types, etc.  The `db:reseed` can be used at any point you want reset the database without
having to close down all clients using the database.

##### Creating individual test correspondence items

Individual correspondence items can be quickly created by logging in as David Attenborough, and using the admin tab to create any kind of case in any state.

##### Creating bulk test correspondence items

To create 200 cases in various states with various responders for search testing, you can use the following rake task:
```
rake seed:search:data
```
It appears that redis needs to be running to attempt this task - but it doesn't currently work for unknown reasons.

### Additional Setup

#### Libreoffice

Libreoffice is used to convert documents to PDF's so that they can be viewed in a browser.
In production environments, the installation of libreoffice is taken care of during the build
of the docker container (see the Dockerfile).

In localhost dev testing environments, libreoffice needs to be installed using homebrew, and then
the following shell script needs to created with the name ```/usr/local/bin/soffice```:


```
cd /Applications/LibreOffice.app/Contents/MacOS && ./soffice $1 $2 $3 $4 $5 $6
```

The above script is needed by the libreconv gem to do the conversion.

#### BrowserSync Setup

[BrowserSync](https://www.browsersync.io/) is setup and configured for local development
using the [BrowserSync Rails gem](https://github.com/brunoskonrad/browser-sync-rails).
BrowserSync helps us test across different browsers and devices and sync the
various actions that take place.

##### Dependencies

Node.js:
Install using `brew install node` and then check its installed using `node -v` and `npm -v`

- [Team Treehouse](http://blog.teamtreehouse.com/install-node-js-npm-mac)
- [Dy Classroom](https://www.dyclassroom.com/howto-mac/how-to-install-nodejs-and-npm-on-mac-using-homebrew)

##### Installing and running:

Bundle install as normal then
After bundle install:

```bash
bundle exec rails generate browser_sync_rails:install
```

This will use Node.js npm (Node Package Manager(i.e similar to Bundle or Pythons PIP))
to install BrowserSync and this command is only required once. If you run into
problems with your setup visit the [Gems README](https://github.com/brunoskonrad/browser-sync-rails#problems).

To run BrowserSync start your rails server as normal then in a separate terminal window
run the following rake task:

```bash
bundle exec rails browser_sync:start
```

You should see the following output:
```
browser-sync start --proxy localhost:3000 --files 'app/assets, app/views'
[Browsersync] Proxying: http://localhost:3000
[Browsersync] Access URLs:
 ------------------------------------
       Local: http://localhost:3001
    External: http://xxx.xxx.xxx.x:3001
 ------------------------------------
          UI: http://localhost:3002
 UI External: http://xxx.xxx.xxx.x:3002
 ------------------------------------
[Browsersync] Watching files...
```
Open any number of browsers and use either the local or external address and your
browser windows should be sync. If you make any changes to assets or views then all
the browsers should automatically update and sync.

The UI URL are there if you would like to tweak the BrowserSync server and configure it further

#### Emails

Emails are sent using
the [GOVUK Notify service](https://www.notifications.service.gov.uk).
Configuration relies on an API key which is not stored with the project, as even
the test API key can be used to access account information. To do local testing
you need to have an account that is attached to the "Track a query" service, and
a "Team and whitelist" API key generated from the GOVUK Notify service website.
See the instructions in the `.env.example` file for how to setup the correct
environment variable to override the `govuk_notify_api_key` setting.

The urls generated in the mail use the `cts_email_host` and `cts_mail_port`
configuration variables from the `settings.yml`. These can be overridden by
setting the appropriate environment variables, e.g.

```
$ export SETTINGS__CTS_EMAIL_HOST=localhost
$ export SETTINGS__CTS_EMAIL_PORT=5000
```

#### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.
In local development, uploads are place in the
[correspondence-staff-case-uploads-testing](https://s3-eu-west-1.amazonaws.com/correspondence-staff-case-uploads-testing/)
bucket.

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

If you have an MoJ account in AWS IAM, you can configure the aws-sdk with your
access and secret key by placing them in the `[default]` section in
`.aws/credentials`:

1. [Retrieve you keys from your IAM account](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)<sup>[1](#user-content-footnote-aws-access-key)</sup> if you don't have them already.
2. [Place them in `~/.aws/credentals`](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html)

When using Docker Compose your `~/.aws` will be mounted onto the containers so
that they can use your local credentials transparently.

#### Using shared credentials

Alternatively, if you don't have an AWS account with access to that bucket, you
can get access by using an access and secret key specifically generated for
testing:

1. Retrieve the 'Case Testing Uploads S3 Bucket' key from the Correspondence
   group in Rattic.
2. [Use environment variables to configure the AWS SDK](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html#aws-ruby-sdk-credentials-environment)
   locally.

#### Footnotes

<a name="footnote-aws-access-key">1</a>: When following these instructions, I had to replace step 3 (Continue to Security Credentials) with clicking on *Users* on the left, selecting my account from the list there, and then clicking on "Security Credentials".

#### Dumping the database

We have functionality to create an anonymised copy of the production or staging database. This feature is to be used as a very last resort. If the copy of the database is needed for debugging please consider the following options first:
- seeing if the issue is covered in the feature tests
- trying to track the issue through Kibana
- recreating the issue locally

If the options above do not solve the issue you by create an anonymised dump of the database by running

```
rake db:dump:prod[host]
```

there are also options to create an anonymised version of the local database

```
rake db:dump:local[filename,anon]
```

or a standard copy

```
rake db:dump:local[filename,clear]
```

For more help with the data dump tasks run:

```
rake db:dump:help
```


### Papertrail

The papertrail gem is used as an auditing tool, keeping the old copies of records every time they are
changed.  There are a couple of complexities in using this tool which are described below:

## JSONB fields on the database
The default serializer does not de-serialize the properties column correctly because internally it is
held as JSON, and papertrail serializes the object in YAML.  The custom serializer ```CtsPapertrailSerializer```
takes care of this and reconstitutes the JSON fields correctly.  See ```/spec/lib/papertrail_spec.rb``` for
examples of how to reify a previous version, or get a hash of field values for the previous version.

### Continuous Integration

Continuous integration is carried out by SemaphoreCI.


### Smoke Tests

The smoke test runs through the process of signing into the service using a dedicated user account setup as Disclosure BMT team member.
It checks that sign in was successful and then randomly views one case in the case list view.

To run the smoke test, set the following environment variables:

```
SETTINGS__SMOKE_TESTS__USERNAME    # the email address to use for smoke tests
SETTINGS__SMOKE_TESTS__PASSWORD    # The password for the smoketest email account
```

and then run

```
bundle exec rails smoke
```

### Deploying

#### Dockerisation

Docker images are built from a single `Dockerfile` which uses build arguments to
control aspects of the build. The available build arguments are:

- _*development_mode*_ enable by setting to a non-nil value/empty string to
  install gems form the `test` and `development` groups in the `Gemfile`. Used
  when building with `docker-compose` to build development versions of the
  images for local development.
- _*additional_packages*_ set to the list of additional packages to install with
  `apt-get`. Used by the build system to add packages to the `uploads` container:

  ```
      clamav clamav-daemon clamav-freshclam libreoffice
  ```

  These are required to scan the uploaded files for viruses (clamav & Co.) and
  to generate a PDF preview (libreoffice).

#### Guide to our deploy process
For our deploy process please see the our [confluence page](https://dsdmoj.atlassian.net/wiki/spaces/CD/pages/164660145/Manual+-+Development+and+Release+Process)

# Case Journey
1. **unassigned**
   A new case entered by a DACU user is created in this state.  It is in this state very
   briefly before it the user assigns it to a team on the next screen.

1. **awaiting_responder**
   The new case has been assigned to a business unit for response.

1. **drafting**
   A kilo in the responding business unit has accepted the case.

1. **pending_dacu_clearance**
   For cases that have an approver assignment with DACU Disclosure, as soon as a
   response file is uploaded, the case will transition to pending_dacu disclosure.
   The DACU disclosure team can either clear the case, in which case it goes forward to
   awaiting dispatch, or request changes, in which case it goes back to drafting.

1. **awaiting_dispatch**
   The Kilo has uploaded at least one response document.

1. **responded**
   The kilo has marked the response as sent.

1. **closed**
   The kilo has marked the case as closed.
