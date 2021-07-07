#!/usr/bin/env bash
############################
# This script tell git to assume that Gemfile.lock .gitignore and all solr log files are unchanged
# that itself is simply a workaround to stop accidental commit to LIVE server.
# Run this script inside the rails project root.
############################

########## Variables

# list of files/folders to assume unchanged
files="db/schema.rb Gemfile.lock .gitignore $(git ls-files solr/development | tr '\n' ' ')"

git update-index --assume-unchanged $files

rm Gemfile.lock
bundle install
