#!/bin/bash
# Build and serve the site locally with the same Jekyll + plugin versions
# GitHub Pages uses (via the github-pages gem). Gems go into vendor/bundle.
set -e
cd "$(dirname "$0")"

# Some macOS Command Line Tools installs ship an incomplete
# usr/include/c++/v1 that shadows the SDK's C++ headers, which breaks
# compiling the eventmachine gem ('iostream' file not found).
if [[ "$(uname)" == "Darwin" ]]; then
  export CPLUS_INCLUDE_PATH="$(xcrun --show-sdk-path)/usr/include/c++/v1"
fi

bundle config set --local path vendor/bundle
bundle check > /dev/null || bundle install

bundle exec jekyll serve --livereload "$@"
