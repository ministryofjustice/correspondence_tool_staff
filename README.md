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

Keep a note of the users generated as this is needed to login to the service.

###System environment Variables

```
#This token will be needed for the Correspondence Tool - Public 
#to make api calls to Correspondence Tool - Staff. Data received via
#the API will only be accepted if the token bettween the two service matches 
WEB_FORM_AUTH_TOKEN = 'WhateverThisIsItWillBeNeededForAPIAccess'
```

