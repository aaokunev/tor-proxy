# Tor proxy + obfs4 bridges (Alpine Linux)

A lightweight Docker image providing a Tor proxy on Alpine Linux with **`obfs4proxy` built from source** (from `Yawning/obfs4`).

- **Base:** Alpine Linux
- **Tor:** Installed via `apk`
- **Obfs4:** Compiled from source (multi-stage build)
- **Tools:** Includes `vim`, `ping` (iputils), `curl`
- **Config:** `torrc` is injected at runtime via bind-mount
- **Permissions:** Handles UID/GID automatically via entrypoint script

## Features & Ports

- **9050/tcp** — SOCKS5 Proxy
- **9053/udp & tcp** — DNSPort (Tor DNS resolving)
- **Persistence:** `/var/lib/tor` (Tor keys, consensus cache, guard nodes)

## Quick Start: Docker Compose (Recommended)

Using Compose is recommended to easily manage configuration and data persistence.

1.  **Create a `torrc` file** (see the [Configuration Example](#configuration-example-torrc) below).
2.  **Create a `docker-compose.yml`**:

```yaml
version: '3.8'

services:
  tor-proxy:
    image: okunev/tor-proxy:latest
    container_name: tor-proxy
    restart: unless-stopped
    ports:
      - "9050:9050"       # SOCKS5
      - "9053:9053/udp"   # DNS (UDP)
      - "9053:9053/tcp"   # DNS (TCP)
    volumes:
      # Mount your configuration file (read-only)
      - ./torrc:/etc/tor/torrc:ro
      # Persist Tor data (keys, cache) to a Docker volume
      - tor_data:/var/lib/tor

volumes:
  tor_data:
```

3.  **Run the container**:
    ```bash
    docker-compose up -d
    ```

## Quick Start: Docker CLI

If you prefer running manual commands:

```bash
docker run -d \
  --name tor-proxy \
  --restart unless-stopped \
  -p 9050:9050 \
  -p 9053:9053/tcp \
  -p 9053:9053/udp \
  -v "$(pwd)/torrc:/etc/tor/torrc:ro" \
  -v "$(pwd)/tor_data:/var/lib/tor" \
  okunev/tor-proxy:latest
```

## Configuration Example (`torrc`)

Save this as `torrc` in your project folder. This template includes settings for Docker compatibility (logging, paths).

> **Need Bridges?**
> Get them from [bridges.torproject.org](https://bridges.torproject.org/options) (Select "obfs4").
> Or email `bridges@torproject.org` with "get transport obfs4" in the body.

```conf
#### Performance
# Enable hardware acceleration if available
HardwareAccel 1

#### Logging (Critical for Docker)
# Log to stdout so 'docker logs' works properly
Log notice stdout

#### Network Ports
# DNS Port (Bind to 0.0.0.0 to allow external container access)
DNSPort 0.0.0.0:9053

# SOCKS5 Proxy Port
SocksPort 0.0.0.0:9050

#### Persistence
# Directory for keys/cache. We mount a volume here.
DataDirectory /var/lib/tor

#### Security & Privacy
# Avoid exiting via specific countries (Example: US, RU, CN)
# Note: This applies to Exit Nodes only.
ExcludeExitNodes {us},{ru},{cn}
StrictNodes 1

#### Bridges Configuration
UseBridges 1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy

# === BRIDGES GO HERE ===
# Bridge obfs4 <IP>:<PORT> <FINGERPRINT> cert=<CERT> iat-mode=0
# Bridge obfs4 <IP>:<PORT> <FINGERPRINT> cert=<CERT> iat-mode=0

```

## Verification

Once the container is running, verify that traffic is being routed through Tor.

**1. Check SOCKS5 Proxy:**
```bash
curl --socks5-hostname localhost:9050 -s https://check.torproject.org/ | grep -i "congratulations"
```
*Expected output: Contains "Congratulations. This browser is configured to use Tor."*

**2. Check DNS Resolution:**
```bash
dig @localhost -p 9053 google.com
```
*Expected output: A valid IP address response.*

**3. Troubleshooting:**
View logs to see Tor bootstrapping progress:
```bash
docker logs -f tor-proxy
```

## Building Locally

To build the image from source:

```bash
docker build -t tor-obfs4:alpine .
```

## Notes on Permissions

- **Data Directory (`/var/lib/tor`):** The image includes an entrypoint script that automatically fixes permissions for the data volume. You do not need to manually `chown` the volume directory.
- **Config File (`torrc`):** Since `torrc` is mounted as a file (bind-mount), ensure it is readable by "others" or by UID 100.
  Run `chmod 644 torrc` on your host machine to ensure the container can read it.
