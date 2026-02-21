# Arr Stack Installer

This Bash script automates the installation of the Arr Stack, a collection of media management applications (such as Sonarr, Radarr, Lidarr, etc.) using Docker and Docker Compose.

## Prerequisites

- A Linux system (Ubuntu/Debian recommended, as the script uses `apt-get`)
- `sudo` access for installing system packages
- Internet connection for downloading Docker and the docker-compose configuration

## Installation

1. **Download the script**:
   - If hosted on GitHub or another repository, clone or download the repository containing `arr-stack.sh`.
   - Alternatively, download the script directly:
     ```bash
     wget https://example.com/path/to/arr-stack.sh
     ```
     Replace `https://example.com/path/to/arr-stack.sh` with the actual URL where the script is hosted.

2. **Make the script executable**:
   ```bash
   chmod +x arr-stack.sh
   ```

3. **Run the script**:
   ```bash
   ./arr-stack.sh
   ```
   The script will:
   - Install Docker if not already installed.
   - Install the Docker Compose plugin if missing.
   - Create the installation directory (`/docker/arr-stack`).
   - Download the `docker-compose.yaml` file from the specified GitHub repository.
   - Create a `.env` file with default configuration variables.

## Post-Installation

After running the script, navigate to the installation directory:
```bash
cd /docker/arr-stack
```

Start the services using Docker Compose:
```bash
docker compose up -d
```

This will start all the Arr Stack services in detached mode.

## Configuration

- The script creates a `.env` file with default settings. You may need to edit this file to customize ports, directories, VPN settings, etc., based on your environment.
- Ensure the directories specified in the `.env` file (e.g., `/volume1/docker/arr-stack`, `/volume1/arr-stack-data`) exist and have appropriate permissions.

## Troubleshooting

- If Docker installation fails, ensure your system is supported by the official Docker installation script.
- For permission issues, make sure your user is added to the `docker` group (the script attempts to do this, but you may need to log out and back in).
- Check the Docker and Docker Compose versions after installation to ensure compatibility.

## License

[Add license information if applicable]

## Contributing

[Add contribution guidelines if applicable]