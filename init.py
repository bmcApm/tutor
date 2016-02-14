#!/usr/bin/env python

# Required for parsing JSON
import json
# Use to generate random measurement values
import random
# Generate current timestamp values
import time
# Import to flush standard out
import sys

# Open the param.json file and parse JSON.
with open("param.json") as f:
    parameters = json.load(f)

# Extract the plugin configuration
source = parameters["source"]
interval = parameters["interval"]

# Metric identifier
metric = 'TUTORIAL_METRIC'

# Run in a continuous loop sending measurements to standard out
while True: 
    # Get the current timestamp
    timestamp = int(time.time())

    # Generate a random value
    value = random.randrange(0, 99)

    # Format measurement string and write to standard out
    sys.stdout.write('{0} {1} {2} {3}\n'.format(metric,value,source,timestamp).decode('utf-8'))
    sys.stdout.flush()

    # Wait for the next interval
    time.sleep(float(interval))
