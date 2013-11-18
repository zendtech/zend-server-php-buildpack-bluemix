#!/usr/bin/env bash

/bin/bash bootstrap.sh

# Start a binary that does nothing so that boot.sh never ends and warden does not kill the container
# This allows apache to be safely restarted by Zend Server (during deploy etc...).
echo "Keep container alive..."

# Keep the app alive so that the health managager does not kill it
exec /app/zend-server-6-php-5.4/bin/donothing
