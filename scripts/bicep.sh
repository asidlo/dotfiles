#!/bin/bash

curl -L https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64 -o /tmp/bicep
chmod +x /tmp/bicep
mv /tmp/bicep ~/.local/bin/bicep
