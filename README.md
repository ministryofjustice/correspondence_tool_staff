# Correspondence Tools - Staff
[![Code Climate](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/gpa.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)
[![Test Coverage](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/coverage.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/coverage)
[![Issue Count](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff/badges/issue_count.svg)](https://codeclimate.com/github/ministryofjustice/correspondence_tool_staff)


An application to allow internal staff users to answer correspondence.

## Development

### Working on the Code

Work should be based off of, and PRed to, the main branch. We use the GitHub
PR approval process so once your PR is ready you'll need to have one person
approve it, and the CI tests passing, before it can be merged. Feel free to use
the issue tags on your PR to indicate if it is a WIP or if it is ready for
reviewing.

Please consider using the provided Docker environment to develop this app over your core linux environment. There are [huge benefits using Docker](https://greatminds.consulting/insight/top-10-benefits-you-will-get-by-using-docker) in development including standardisation, increased productivity and CI efficiencies.

### Basic setup using Docker

#### Requirements

* [Docker](https://docs.docker.com/desktop/install/mac-install/)
* [Dory Proxy](https://github.com/FreedomBen/dory) - _provides named hosts via reverse proxy, allowing multiple apps to use localhost at one time._
* [Docker Sync](https://docker-sync.readthedocs.io/en/latest/index.html) - _provides high-performance 2-way synchronisation of files between host and app containers._

Setup is simple; local-dev is configured to manage the implementation of both Dory and Docker Sync.

Install Dory

```
brew install dory
```

Install Docker Sync

```
gem install docker-sync
```

### Getting started

Clone this repository then `cd` into the new directory

```
$ git clone git@github.com:ministryofjustice/correspondence_tool_staff.git
$ cd correspondence_tool_staff
```

Environment settings for Docker reside in `.env.example`. When starting Docker the environment will be created for you.


> When the service is up and running, an array of pseudo accounts will have been created.
> The password that is defined in the variable `DEV_PASSWORD` will be needed to access all pseudo accounts.

### Installation

The easiest way to get the app running is to execute Makefile commands.

>The `make` utility is commonly used as a compiler however we use it as a stage to combine, execute and compress
more cumbersome commands.

Running the following will get the application started. Please be patient, this process may take a good few minutes to
complete and `dory up` will require root access to write to the host resolver - this is expected.

```
dory up
make build
```
Once the installation process has completed, a Puma server will be running in your terminal.

The application will be available at the following addresses:

**Application:**
```
http://track-a-query.docker/users/sign_in
```

**DB Admin** (login details in `docker-compose.yml`):
```
http://pgadmin.track-a-query.docker:5050/
```

**Selenium Grid UI** (feature tests):
```
http://chrome.track-a-query.docker/ui
```

**BrowserSync:**
```
http://track-a-query.docker:3001/
```

**BrowserSync UI:**
```
http://track-a-query.docker:3002/
```

> During usual operation it is normal to `make down` and `make launch` to stop and start the application, respectively.

### Working in the terminal

Run the following in a separate terminal window.

```
make shell
```

From this prompt, You can run `irb`, `rails c` and a host of other commands.

**IMPORTANT**; the following removes all data and volumes... to nuke the entire installation and rebuild the app, run:

```
make rebuild
```

### The Testing Environment

The `docker compose` environment comes packed with a dedicated testing environment that requires an initial setup.

In a separate terminal window, execute:

```
make specs
```

Once the interface has initialised, execute:

```
make spec-setup
```

Once set up has completed you won't have to run that again unless the volumes are removed.

------------

### Make commands

There are several `make` commands configured in the `Makefile`. These are mostly just convenience wrappers for longer or more complicated commands.

Nb. with exception to `make spec-setup`, all other `make` commands are run from the host machine, i.e. outside the containers.

| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `make docker-shell`                                                                                                                   | Generate an .env file (if not exist), run the app in the background and open an interactive shell.<br/>***Nb.*** does not launch servers for browser viewing, run `make build` instead. This command is for accessing a detached app container in order to execute administrative operations. You may like to run `make shell` to open a prompt in the container launched by `docker compose up`. From within you can run commands such as  `irb` and `rails c` |
| `make`                                                                                                                                | Alias of `make docker-shell`.                                                                                                                                                                                                                                                                                                                                                                                                                                   |
| `make build`                                                                                                                          | Build and run the application in the background, launch Sidekiq, BrowserSync and Puma.                                                                                                                                                                                                                                                                                                                                                                          |
| `make launch`                                                                                                                         | Run the application in the background, launch Sidekiq, BrowserSync and Puma.                                                                                                                                                                                                                                                                                                                                                                                    |
| `make rebuild`                                                                                                                        | Runs `make dc-clean` and then rebuilds the application from the ground up and brings it online.                                                                                                                                                                                                                                                                                                                                                                 |


### Other helpers
Whilst these can be used independently, they are generally used in the commands above to help overcome complex
installation.

| Command&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Description                                                                                                                                                           |
|---------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `make setup`                                                                                                                          | Jump into the app container and execute the `install.sh` script                                                                                                       |
| `make sidekiq`                                                                                                                        | Launch Sidekiq in the background.                                                                                                                                     |
| `make browser-sync`                                                                                                                   | Launch BrowserSync in the background.                                                                                                                                 |
| `make server`                                                                                                                         | Launch Puma at the command prompt.                                                                                                                                    |
| `make servers`                                                                                                                        | A helper to ensure app setup and asynchronously start all servers in this order; Sidekiq, BrowserSync and Puma.                                                       |
| `make dc-clean`                                                                                                                       | Stop all CTS docker containers, delete all CTS images, volumes and network. Clean the application directory ready for a fresh installation. Nukes databases and Gems. |
| `make dc-reset`                                                                                                                       | Clean and rebuild the app, displays stdout ***doesn't restart the servers***                                                                                          |
| `make down`                                                                                                                           | Alias of `docker compose down`                                                                                                                                        |
| `make up`                                                                                                                             | Alias of `docker compose up`                                                                                                                                          |
| `make up-daemon`                                                                                                                      | Alias of `docker compose up -d app` - run docker compose in the background                                                                                            |
| `make restart`                                                                                                                        | Stop docker compose (`down`), relaunch (`up`) and display an interactive shell on the app container                                                                   |
| `make shell-app`                                                                                                                      | Open an interactive command prompt on the app container                                                                                                               |
| `make test`                                                                                                                           | Run tests on the application.                                                                                                                                         |
| `make docker-sync`                                                                                                                    | Starts a docker-sync container used to speed up development on the front end.                                                                                         |


---------------

> Below is the normal setup outside of Docker. Please consider using Docker as the environment can more closely match production, rather than your machines environment.

### Testing

This project can produce code coverage data (w/o JS or views) using the `simplecov` gem
set COVERAGE=1 (or any value) to generate a coverage report.
Parallel tests are supposed to be supported - however the coverage output from simplecov is a little
strange (the total lines in the project are different for each coverage run)

This project includes the `parallel_tests` gem which enables multiple CPUs to be used during testing
in order to speed up execution. Otherwise running the tests takes an unacceptably long amount of time.

The default parallelism is 8 (override by setting PARALLEL_TEST_PROCESSORS) which seems to be about
right for a typical Macbook Pro (10,1 single processor with 4 cores)

#### To set up parallel testing

Create the required number of extra test databases:
```
rails parallel:create
```
Load the schema into all of the extra test databases:
```
rails parallel:load_structure
```
##### To run all the tests in parallel
```
rails parallel:spec
```
##### To run only feature tests in parallel
```
rails parallel:spec:features
```
##### To run only the non-feature tests in parallel
```
rails parallel:spec:non_features
```

#### Browser testing

We use chromedriver for Capybara tests, which require JavaScript. This is managed by selenium-webdriver.

If you have an existing version on your PATH this may cause an issue so you will need to remove it from your PATH
or uninstall it.

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
If you have a `debugger`  in your tests the browser will stop at that point.

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

#### Devise OmniAuth - Azure Active Directory

In addition to sign in with email and password, there is an integration with
Azure Active Directory through Devise OmniAuth.

For this to work in your local machine, you will need to set 3 ENV variables.
See the instructions in the `.env.example` file.

A colleague can provide this to you. Usually, the tenant and client will be
the same for all local/dev environments, but the secret should be unique to
your machine, as this makes it easier to revoke it in case of a leak.

This feature can be enabled/disabled through the `enabled_features` mechanism
configured in [config/settings.yml](config/settings.yml).

#### Uploads

Responses and other case attachments are uploaded directly to S3 before being
submitted to the application to be added to the case. Each deployed environment
has the permissions is needs to access the uploads bucket for that environment.

In local development, uploads are placed in https://<cloud-platform-generated-s3-bucket-address>/

You'll need to provide access credentials to the aws-sdk gems to access
it, there are two ways of doing this:

#### Using credentials attached to your IAM account

In order to perform certain actions, you need to have valid S3 credentials active
You can configure the aws-sdk with your access and secret key by placing them in
 the `[default]` section in `.aws/credentials`:

Retrieve details from the secret created in Kubernetes in the  [s3.tf terraform resource](https://github.com/ministryofjustice/cloud-platform-environments/blob/master/namespaces/live.cloud-platform.service.justice.gov.uk/track-a-query-development/resources/s3.tf#L74)


`kubectl -n track-a-query-production get secret track-a-query-ecr-credentials-output -o yaml`

Decode the base64 encoded values for access_key_id and secret_access_key from the output returned e.g.

`$ echo QUtHQTI3SEpTERJV1RBTFc= | base64 --decode; echo`

Place them in `~/.aws/credentals` as the default block:

```
[default]
aws_access_key_id = AKIA27HHJDDH3GHI
aws_secret_access_key = lSlkajsd9asdlaksd73hLKSFAk

```

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

#### JSONB fields on the database
The default serializer does not de-serialize the properties column correctly because internally it is
held as JSON, and papertrail serializes the object in YAML.  The custom serializer ```CtsPapertrailSerializer```
takes care of this and reconstitutes the JSON fields correctly.  See ```/spec/lib/papertrail_spec.rb``` for
examples of how to reify a previous version, or get a hash of field values for the previous version.

### Continuous Integration

Continuous integration is carried out by SemaphoreCI.

### Data Migrations

The app uses the `rails-data-migrations` gem https://github.com/OffgridElectric/rails-data-migrations

Data migrations work like regular migrations but for data; they're found in `db/data_migrations`.

To create a data migration you need to run:

`rails generate data_migration migration_name`

and this will create a `migration_name.rb` file in `db/data_migrations` folder with the following content:

```
class MigrationName < DataMigration
  def up
    # put your code here
  end
end
```

Finally, at release time, you need to run:

`rake data:migrate`

This will run all pending data migrations and store migration history in data_migrations table.

### Letter templates and synchronising data

The app has templated correspondence for generating case-related letters for the Offender SAR case type.

The template body for each letter is maintained in the `letter_templates` table in the database, and populated from information in the /db/seeders/letter_template_seeder.rb script.

Whenever any changes to the letter templates are required DO NOT EDIT THE DATABASE, but amend the seeder and then on each environment, run `rails db:seed:dev:letter_templates` to delete and re-populate the table.

This is required whenever any new template is added; should someone have edited the versions in the database directly, those changes will be overwritten the next time the seeder is run.

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
### Site prism page manifest file

The tests use the Site Prism gem to manage page objects which behave as an abstract description of the pages in the application; they're used in feature tests for finding elements, describing the URL path for a given page and for defining useful methods e.g. for completing particular form fields on the page in question.

If you add new Site Prism page objects, it's easy to follow the existing structure - however, there is one gotcha which is that in order to refer to them in your tests, you also need to add the new objects to a manifest file here so that it maps an instantiated object to the new Page object class you've defined.

See `spec/site_prism/page_objects/pages/application.rb`

### Localisation keys checking

As part of the test suite, we check to see if any `tr` keys are missing from the localised YAML files

There is a command line tool provided to check for these manually as well - `i18n-tasks missing` - you can see the output from it below.

```
$ i18n-tasks missing
Missing translations (1) | i18n-tasks v0.9.29
+--------+------------------------------------+--------------------------------------------------+
| Locale | Key                                | Value in other locales or source                 |
+--------+------------------------------------+--------------------------------------------------+
|  all   | offender_sars.case_details.heading | app/views/offender_sars/case_details.html.slim:5 |
+--------+------------------------------------+--------------------------------------------------+

...fixing happens...

$ i18n-tasks missing
✓ Good job! No translations are missing.
$
```
There's also a similar task called `i18n-tasks unused`

```
$ i18n-tasks unused
Unused keys (1) | i18n-tasks v0.9.29
+--------+-----------------------+---------------+
| Locale | Key                   | Value         |
+--------+-----------------------+---------------+
|   en   | steps.new.sub_heading | Create a case |
+--------+-----------------------+---------------+
$ i18n-tasks unused
✓ Well done! Every translation is in use.
$
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


  ```
      nodejs
  ```

  Required to run Puma with ExecJS


  ```
      zip
  ```

  Required to run closed case reports

  ```
      postgresql-client-12.6-r0
  ```

  Required for debugging database by developers within the running container - app will work without this.

#### ARM Mac Users

If you are creating a local image for deploying to an environment, you will need to change the target platform by running:

```
export DOCKER_DEFAULT_PLATFORM=linux/amd64
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

#### Guide to our deploy process
For our deploy process please see the our [confluence page](https://dsdmoj.atlassian.net/wiki/spaces/CD/pages/164660145/Manual+-+Development+and+Release+Process)


## Keeping secrets and sensitive information secure

There should be *absolutely no secure credentials* committed in this repo. Information about secret management can be found in the related confluence pages.

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

# How to upgrade Ruby 2.7.x to Ruby 3.x on local environment

1. Install Ruby 3.x

```
$ rbenv install
```
it should pick up the version defined in .ruby-version

If you get error somehow telling you not being able to find available stable release 3.x, you could try the following commands

```
$ brew unlink ruby-build
$ brew install --HEAD ruby-build
```

then run following command to check whether you can see 3.x in the list
```
$ rbenv install --list-all
```
once you confirm, you can re-run `rbenv install` comand to continue the process.

3. Update the gem system
```
$ gem update --system
```

4. Install bundle 2.4.13 and install those gems
```
$ gem install bundler -v 2.4.13
$ bundler install
```

5. run `rails s` check the app

## Dependabot

Dependabot creates PRs to help us keep track of our dependency updates. This is great but can lead to a little bit of work if you integrate these changes one by one (for instance, having to run the test suite over and over again).

You can manually combine the changes into one PR and then push this and wait for the tests to run, but this is admin that can be automated so why bother?

The app has a github action "Combine PRs" which automatically combines dependabot PRs that have passed the test suite into one PR which you can then merge.

To use this: "Actions" > "All workflows" > on the left "Combine PRs" > "Run workflows"

See here for the [original developers README](https://github.com/hrvey/combine-prs-workflow)

## Addendum

Please note: the file upload functionality will not work locally without an AWS S3 bucket setup as a file store.
