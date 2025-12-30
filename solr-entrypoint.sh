#!/bin/bash
# Increase ulimit at container startup
ulimit -n 65536

# Start Solr normally
exec docker-entrypoint.sh solr -f
