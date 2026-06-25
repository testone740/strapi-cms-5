#!/bin/bash

# Ref: https://docs.strapi.io/cms/data-management/export

## Notes
# This script does NOT compress or encrypt data to facilitate data import
# Use only one command

npm run strapi export -- --file $(pwd)/data/sample_data_$(date +%Y%m%d) --no-compress --no-encrypt

# yarn strapi export -f $(pwd)/data/sample_data_$(date +%Y%m%d) --no-compress --no-encrypt
