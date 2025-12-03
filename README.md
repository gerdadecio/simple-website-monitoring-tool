# Website Monitoring App

A simple, lightweight website monitoring application that displays the status of multiple websites in an HTML table. Built with Docker, HTML, JavaScript, and Bash scripts using curl for HTTP requests.

## Features

- Real-time monitoring of multiple website endpoints
- Displays status code, version, response time, and last checked timestamp
- Color-coded status indicators (green for success, yellow for redirects, red for errors)
- Auto-refresh every 30 seconds
- Manual refresh button
- Responsive design
- Dockerized for easy deployment

## Prerequisites

- Docker installed on your system
- Basic understanding of Docker commands

## Quick Start

### 1. Copy the sample config file and update accordingly

```bash
cp config.sample.json config.json
```

### 2. Build the Docker Image

```bash
docker build -t website-monitor .
```

### 3. Run the Container

```bash
docker run -d -p 8080:80 --name monitor website-monitor
```

### 4. Access the Dashboard

Open your browser and navigate to:

```
http://localhost:8080
```

## Configuration

### Adding or Modifying Endpoints

To monitor different websites, edit the `check_status.sh` file and modify the `ENDPOINTS` array:

```bash
ENDPOINTS=(
    "https://your-website.com/api/status"
    "https://another-site.com/health"
    "https://example.com"
)
```

After modifying, rebuild the Docker image:

```bash
docker build -t website-monitor .
docker stop monitor
docker rm monitor
docker run -d -p 8080:80 --name monitor website-monitor
```

### Adjusting Check Interval

By default, the status check runs every 60 seconds. To change this, edit `start.sh` and modify the `sleep` value:

```bash
sleep 60  # Change to desired interval in seconds
```

### Adjusting Auto-Refresh Interval

The dashboard auto-refreshes every 30 seconds. To change this, edit `index.html` and modify the interval in the JavaScript:

```javascript
setInterval(loadStatus, 30000);  // Change 30000 to desired milliseconds
```

## Project Structure

```
.
├── Dockerfile              # Docker configuration
├── .dockerignore          # Docker ignore file
├── config.json            # Config file for the monitoring page
├── config.sample.json     # Sample config file for the monitoring page
├── index.html             # Main dashboard HTML
├── check_status.sh        # Status checking script
├── start.sh               # Container startup script
├── README.md              # This file
```

## How It Works

1. **Container Startup**: When the container starts, `start.sh` is executed
2. **Initial Check**: The status check script runs immediately to generate initial data
3. **Background Loop**: A background process runs the status checker every 60 seconds
4. **Web Server**: Nginx serves the HTML dashboard on port 80
5. **Data Flow**: The status checker writes to `status.json`, which the dashboard reads via AJAX
6. **Auto-Refresh**: JavaScript automatically reloads the data every 30 seconds

## Status Indicators

- **Green (2xx)**: Success - endpoint is healthy
- **Yellow (3xx)**: Redirect - endpoint redirects to another URL
- **Orange/Red (4xx)**: Client error - issue with the request
- **Red (5xx)**: Server error - endpoint is experiencing issues
- **Gray**: Unknown - unable to determine status

## Version Detection

The app attempts to detect version information from:
1. Response headers: `X-Version`, `X-API-Version`, or `API-Version`
2. JSON response body: `"version"` field
3. Falls back to "N/A" if no version is found

## Docker Commands

### View Logs
```bash
docker logs monitor
```

### Stop Container
```bash
docker stop monitor
```

### Remove Container
```bash
docker rm monitor
```

### Restart Container
```bash
docker restart monitor
```

### Execute Commands Inside Container
```bash
docker exec -it monitor /bin/bash
```

## Troubleshooting

### Dashboard shows "Error loading data"

1. Check if the container is running: `docker ps`
2. View container logs: `docker logs monitor`
3. Verify the status checker is running: `docker exec -it monitor ps aux | grep check_status`

### No data appearing

1. Check if `status.json` exists: `docker exec -it monitor cat /usr/share/nginx/html/status.json`
2. Manually run the status checker: `docker exec -it monitor /usr/local/bin/check_status.sh`

### Endpoints timing out

- Increase the timeout in `check_status.sh` by modifying `--max-time 10` to a higher value

## Customization

### Styling

Edit the `<style>` section in `index.html` to customize colors, fonts, and layout.

### Table Columns

To add or remove columns:
1. Modify the `<th>` elements in `index.html`
2. Update the JavaScript data population logic
3. Adjust the `check_status.sh` script to collect the required data

## Performance Considerations

- Each endpoint check is sequential, so total check time increases with more endpoints
- Consider adjusting check intervals if monitoring many endpoints
- Response times are in milliseconds
- The container uses minimal resources (Alpine Linux + nginx)

## Security Notes

- This app is designed for internal monitoring
- Endpoints are currently hardcoded in the script
- No authentication is implemented on the dashboard
- For production use, consider adding:
  - HTTPS support
  - Authentication
  - Environment variables for configuration
  - Persistent storage for historical data

## License

This project is provided as-is for monitoring purposes.

## Support

For issues or questions, refer to the implementation plan in `plan.md`.
