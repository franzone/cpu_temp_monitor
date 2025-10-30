#!/bin/bash

# CPU Temperature Monitoring Script with Alerts
# Supports email and Discord notifications
# Configuration: See cpu_temp_monitor.conf or set environment variables

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/cpu_temp_monitor.conf"

# Load configuration from file if it exists
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# Fall back to environment variables if not set by config file
: "${LOG_FILE:=/var/log/cpu_warning.log}"
: "${ERROR_LOG_FILE:=/var/log/cpu_critical.log}"
: "${EMAIL_ADDRESS:=${CPU_MONITOR_EMAIL}}"
: "${DISCORD_WEBHOOK:=${CPU_MONITOR_DISCORD_WEBHOOK}}"

# Validate required parameters
if [ $# -ne 2 ]; then
  echo "Error: Missing required parameters."
  echo "Usage: $0 <warning_temp> <critical_temp>"
  echo ""
  echo "Example: $0 158 176"
  echo ""
  echo "Configuration:"
  echo "  - Create cpu_temp_monitor.conf in the same directory as this script, or"
  echo "  - Set environment variables: CPU_MONITOR_EMAIL, CPU_MONITOR_DISCORD_WEBHOOK"
  exit 1
fi

# Validate configuration
if [ -z "$EMAIL_ADDRESS" ] && [ -z "$DISCORD_WEBHOOK" ]; then
  echo "Error: No alert methods configured."
  echo "Please set EMAIL_ADDRESS and/or DISCORD_WEBHOOK in cpu_temp_monitor.conf"
  exit 1
fi

WARNING_TEMP="$1"
CRITICAL_TEMP="$2"

echo "JOB RUN AT $(date)" | sudo tee -a "$LOG_FILE" >/dev/null
echo "CPU Warning Limit: ${WARNING_TEMP}°F"
echo "CPU Shutdown Limit: ${CRITICAL_TEMP}°F"

sensors_output=$(sensors -f)
echo "$sensors_output"

# Initialize message variables
warning_message=""
critical_alert=0

# Extract all core temperature lines
core_lines=$(echo "$sensors_output" | grep -E '^Core [0-9]+:')

# Loop through each core line
while read -r line; do
  core=$(echo "$line" | awk '{print $1 " " $2}' | sed 's/://')  # e.g., "Core 0"
  temp=$(echo "$line" | grep -oP '\+\K\d+(\.\d+)?' | head -1 | cut -d'.' -f1)  # Extract integer temp

  if [ "$temp" -ge "$CRITICAL_TEMP" ]; then
    # Critical temperature detected
    echo "$(date) CRITICAL: $core exceeded ${CRITICAL_TEMP}°F (at ${temp}°F) - Shutting down" | sudo tee -a "$ERROR_LOG_FILE" >/dev/null
    warning_message="${warning_message}CRITICAL: $core at ${temp}°F\n"
    critical_alert=1
  elif [ "$temp" -ge "$WARNING_TEMP" ]; then
    # Warning temperature detected
    echo "$(date) WARNING: $core exceeded ${WARNING_TEMP}°F (at ${temp}°F)" | sudo tee -a "$LOG_FILE" >/dev/null
    warning_message="${warning_message}WARNING: $core at ${temp}°F\n"
  else
    echo "$core OK at ${temp}°F"
  fi
done <<< "$core_lines"

# Send bundled email and Discord notification if there were any warnings or critical alerts
if [ -n "$warning_message" ]; then
  if [ $critical_alert -eq 1 ]; then
    # Send email alert if configured
    if [ -n "$EMAIL_ADDRESS" ]; then
      echo -e "CPU Temperature Critical Alert:\n\n$warning_message\nServer shutting down." | mail -r "${EMAIL_FROM}" -s "CPU Temperature Critical" "$EMAIL_ADDRESS"
    fi
    
    # Send Discord alert if configured
    if [ -n "$DISCORD_WEBHOOK" ]; then
      curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"content\":\"🚨 **CPU Temperature Critical Alert**\n\n$warning_message\n\nServer shutting down.\"}" \
        "$DISCORD_WEBHOOK"
    fi
    
    # Uncomment to enable automatic shutdown
    # sudo shutdown -h now
  else
    # Send email alert if configured
    if [ -n "$EMAIL_ADDRESS" ]; then
      echo -e "CPU Temperature Warning:\n\n$warning_message" | mail -r "${EMAIL_FROM}" -s "CPU Temperature Warning" "$EMAIL_ADDRESS"
    fi
    
    # Send Discord alert if configured
    if [ -n "$DISCORD_WEBHOOK" ]; then
      curl -s -X POST -H 'Content-type: application/json' \
        --data "{\"content\":\"⚠️ **CPU Temperature Warning**\n\n$warning_message\"}" \
        "$DISCORD_WEBHOOK"
    fi
  fi
fi

echo "All cores within limits"
