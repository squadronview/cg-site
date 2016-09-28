#!/bin/sh

set -e
set -x

# build the site
npm run build
hugo

# copy files to output directory, so that they can be read by subsequent step
if [ -n "$COPY_OUTPUT" ]; then
  cp -R . ../cg-docs-compiled
fi
