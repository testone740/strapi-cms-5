#!/bin/bash

# Ref: https://docs.strapi.io/cms/data-management/import

# Import data from an existing .tar file (ex: sample_data_20260624.tar)

npm run strapi import -- -f $(pwd)/data/sample_data_20260624.tar --force

# yarn strapi import -f $(pwd)/data/sample_data_$(date +%Y%m%d).tar --force

