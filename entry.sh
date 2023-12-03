#!/bin/bash

config_file="${CONFIGFILE:-/data/zap2itconfig.ini}"
output_file="${OUTPUTFILE:-/data/xmlguide.xmltv}"
output_dir="$(dirname "$output_file")"
date_format="%Y-%m-%d %H:%M:%S %Z"

# Ping a healthcheck.io endpoint
healthcheck_io() {
  [ "$1" ] && local url_path="/${1}" || local url_path=""
  if [ "$HEALTHCHECK_URL" ]; then
    curl -fsS -m 10 --retry 5 -o /dev/null "$HEALTHCHECK_URL$url_path"
  fi
}

# Validate some checks before running main
validate() {
  # Check output dir
  if [ ! -d "$output_dir" ] || [ ! -w "$output_dir" ]; then
    echo "Directory does not exist or is not writable...exiting"
    exit 1
  fi

  # Check for config file
  if [ ! -f "$config_file" ]; then
    echo "Can't find $config_file...exiting"
    exit 1
  fi
}

zap2it() {
  echo "Started: $(date +"$date_format")"

  # Run script
  python /zap2it/zap2it-GuideScrape.py \
    --configfile "$config_file" \
    --outputfile "$output_file" \
    --language "${LANGUAGE:-en}"

  echo "Finished: $(date +"$date_format")"

  # remove historical files
  rm "$output_dir"/xmlguide.2*.xmltv
}

main() {
  # Loop if sleeptime is defined
  if [ "$SLEEPTIME" ]; then
    while true; do
      echo "Running zap2it"
      zap2it

      echo "Next: $(date +"$date_format" -d "+$SLEEPTIME seconds")"

      # sleep until next run
      sleep "$SLEEPTIME"
    done
  else
    echo "Running zap2it"
    zap2it
  fi

}

# Run the scripts functions
healthcheck_io "start"
validate
main
healthcheck_io
