#!/bin/sh
set +ex

# This hook wil be executed via gem Overcommit rather than by git directly.
# Ensure you have initialised:
#
# $> overcommit --install
#
# See ./overcommit.yml for the full list of hook settings

# Pre-commit hook to avoid accidentally adding unencrypted files which are
# configured to be encrypted with [git-crypt](https://www.agwa.name/projects/git-crypt/)
# Fix to [Issue #45](https://github.com/AGWA/git-crypt/issues/45)
#
test -d .git-crypt && git-crypt status &>/dev/null
if [[ $? -ne 0 ]]; then
 echo "git-crypt has some warnings"
 git-crypt status -e
 exit 1
fi

################################################################################
# Check for any filenames containing "secret" in the list of files which are not
# encrypted with git-crypt:
#
# Exclude Rails required config/secrets from checks
git-crypt status -u | grep secret | grep -v 'config/secrets.yml'

# grep returns 0 if it finds some matches and 1 if there are no matches:
if [[ $? -eq 0 ]]; then
 echo "Found a secrets file which is not encrypted with git-crypt"
 echo "Did you mean to add this file to the git-crypt config in .gitattributes?"
 exit 1
fi
