# NetBird Add-on for Home Assistant

![NetBird Logo](https://community-assets.home-assistant.io/original/4X/a/0/b/a0b9bbbc720a7a8638537bfd2dfc0c91f6a92dfe.png)

## Overview

The **NetBird Add-on** allows you to securely connect your Home Assistant instance to your **NetBird** network using a lightweight WireGuard-based overlay.  
This makes your Home Assistant accessible through your existing NetBird setup, without exposing any ports to the internet.

NetBird automatically handles secure peer-to-peer connections and NAT traversal, making remote access simple and safe.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2FF1mmel%2FNetbird_HomeAssistant
)

---

## ✨ Features

- 🔒 Secure connection using WireGuard
- 🔗 Persistent configuration between restarts
- 🧠 Automatic re-connection on boot
- 🧰 Custom hostname support (shown in NetBird dashboard)
- ⚙️ Web interface served via built-in Nginx
- 🔧 Configurable Nginx port and Home Assistant host/port

---

## 🧩 Configuration

The add-on uses the following configuration options:

| Option               | Type | Description |
|----------------------|------|-------------|
| `endpoint`           | str  | NetBird management URL (e.g. `https://netbird.example.com`) |
| `token`              | str  | Setup key for adding this device to your NetBird network |
| `hostname`           | str  | Optional: Custom hostname for this device (default: HomeAssistant) |
| `nginx_port`         | int  | Port on which the internal Nginx web interface will listen |
| `homeassistant_ip`   | str  | IP address of the Home Assistant host (used for proxying requests) |
| `homeassistant_port` | int  | Port of Home Assistant (usually 8123) |

### Example Configuration

```yaml
endpoint: "https://netbird.example.com"
token: "YOUR_SETUP_KEY_HERE"
hostname: "HomeAssistant"
nginx_port: 8888
homeassistant_ip: "192.168.178.53"
homeassistant_port: 8123
```
### Access via NetBird

Once the add-on is connected to your NetBird network, you can access your Home Assistant instance securely via:

**http://NETBIRD_PEER_IP:nginx_port**

- `NETBIRD_PEER_IP` is the IP assigned to your Home Assistant device in the NetBird network.  
- `nginx_port` is the port you configured in the add-on options (`nginx_port`).  

For example, if your NetBird peer IP is `100.97.71.93` and `nginx_port` is `8888`, you can open:

**http://100.97.71.93:8888**

in your browser to reach Home Assistant through the NetBird network.

