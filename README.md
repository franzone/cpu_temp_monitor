# CPU Temperature Monitoring Script

A bash script for monitoring CPU temperatures on Ubuntu servers with alerts via email and/or Discord. Automatically shuts down the server if critical thresholds are exceeded.

## Features

- Monitor CPU core temperatures in Fahrenheit
- Configurable warning and critical thresholds
- Bundled alerts (single notification per check cycle)
- Multiple alert methods:
  - Email (including email-to-SMS gateways)
  - Discord webhooks
- Automatic server shutdown on critical temperatures
- Logging to system files
- Easily schedulable via cron

## Prerequisites

- Ubuntu/Debian system
- `lm-sensors` package installed and configured
- `mailutils` for email alerts (optional)
- `curl` for Discord alerts (optional)

### Setup lm-sensors

```bash
sudo apt update
sudo apt install lm-sensors

# Configure sensors
sudo sensors-detect

# Reboot if needed
sudo reboot

# Verify sensors are working
sensors -f
```

### Setup Email Alerts (Optional)

```bash
sudo apt install mailutils
sudo dpkg-reconfigure postfix

# Select "Internet with smarthost" for most setups
# Configure relay host (e.g., smtp.gmail.com:587 for Gmail)
```

## Installation

1. Clone or download this repository
2. Copy the script:
   ```bash
   chmod +x cpu_temp_monitor.sh
   ```

3. Create config file:
   ```bash
   cp cpu_temp_monitor.conf.example cpu_temp_monitor.conf
   nano cpu_temp_monitor.conf
   ```

## Configuration

### Method 1: Config File (Recommended)

Edit `cpu_temp_monitor.conf`:

```bash
# Email alerts (email-to-SMS gateway example)
EMAIL_ADDRESS="1234567890@txt.att.net"
EMAIL_FROM="your-email@gmail.com"

# Discord alerts
DISCORD_WEBHOOK="https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"

# Log locations (optional)
LOG_FILE="/var/log/cpu_warning.log"
ERROR_LOG_FILE="/var/log/cpu_critical.log"
```

**Note:** The config file must be in the same directory as the script.

### Method 2: Environment Variables

Alternatively, set environment variables:

```bash
export CPU_MONITOR_EMAIL="1234567890@txt.att.net"
export CPU_MONITOR_DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
```

### Getting a Discord Webhook URL

1. Go to your Discord server
2. Settings > Integrations > Webhooks
3. Click "New Webhook"
4. Copy the webhook URL
5. Add to your config file

### Email Alert Options

**Email-to-SMS Gateway (US carriers):**
- AT&T: `1234567890@txt.att.net`
- T-Mobile: `1234567890@tmomail.net`
- Verizon: `1234567890@vtext.com`

Or send to regular email: `your@email.com`

## Usage

### Manual Run

```bash
# Warn at 158°F, shutdown at 176°F
./cpu_temp_monitor.sh 158 176

# Warn at 149°F, shutdown at 167°F (more aggressive)
./cpu_temp_monitor.sh 149 167
```

### Scheduling with Cron

Edit your crontab:

```bash
crontab -e
```

Add this line to run every 5 minutes:

```bash
*/5 * * * * /path/to/cpu_temp_monitor.sh 158 176 >/dev/null 2>&1
```

For automatic shutdown, allow sudo shutdown without password:

```bash
sudo visudo
```

Add this line:

```
YOUR_USERNAME ALL=(ALL) NOPASSWD: /sbin/shutdown
```

## Temperature Thresholds

Recommended Fahrenheit thresholds (adjust based on your hardware):

- **Conservative:** `./cpu_temp_monitor.sh 158 176` (70°C / 80°C)
- **Moderate:** `./cpu_temp_monitor.sh 149 167` (65°C / 75°C)
- **Aggressive:** `./cpu_temp_monitor.sh 140 158` (60°C / 70°C)

Check your hardware specs and BIOS limits for guidance.

## Testing

Test with low thresholds to verify alerts work:

```bash
./cpu_temp_monitor.sh 20 50
```

You should receive Discord and/or email alerts.

## Logs

- **Warning log:** `/var/log/cpu_warning.log`
- **Critical log:** `/var/log/cpu_critical.log`

View logs:

```bash
sudo tail -20 /var/log/cpu_warning.log
```

## Troubleshooting

### No Alerts

1. Check config file is in same directory as script
2. Verify settings with: `./cpu_temp_monitor.sh 20 50`
3. Check logs: `sudo tail /var/log/cpu_warning.log`
4. Test email: `echo "Test" | mail -s "Test" your@email.com`
5. Test Discord webhook with curl

### Email Not Sending

```bash
# Check mail logs
sudo tail -f /var/log/mail.log

# Test mail command
echo "Test" | mail -s "Test" your@email.com

# Check DNS
nslookup gmail.com
```

### Cron Not Running

1. Verify cron entry: `crontab -l`
2. Check system logs: `sudo grep CRON /var/log/syslog`
3. Ensure script path is absolute in crontab

## Security Notes

- Store config file securely (not world-readable)
- Don't commit `cpu_temp_monitor.conf` to version control (use `.example` template)
- Use email-to-SMS gateways cautiously (your phone number in config)
- Rotate Discord webhooks if exposed

## License

Feel free to modify and use as needed.

## Contributing

Improvements and fixes welcome!
