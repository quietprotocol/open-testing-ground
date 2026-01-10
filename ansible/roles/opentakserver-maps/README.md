# OpenTAKServer Maps Role

Uploads ATAK map source definitions from [getgotak.com](https://getgotak.com/maps) to OpenTAKServer.

## What it does

Downloads `ATAK-Maps.zip` which contains XML definitions for various map tile sources:
- Google (Hybrid, Roadmap, Satellite, Terrain)
- Bing (Hybrid, Maps)
- ESRI (Clarity, National Geographic, USA Topo, World Topo)
- OpenStreetMap (CycleOSM, OpenTopoMap)
- USGS (Basemap, Imagery, Topo, Shaded Relief)
- And more...

These map sources will be available to ATAK/iTAK users when they connect to the server.

## Requirements

- `curl` must be installed on the control machine
- OpenTAKServer must be running and accessible
- Valid admin credentials for OpenTAKServer

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `opentakserver_host` | `ots.marmal.duckdns.org` | OTS hostname |
| `opentakserver_port` | `8880` | OTS HTTP port |
| `opentakserver_username` | `administrator` | OTS admin username |
| `opentakserver_password` | `password` | OTS admin password |
| `maps_download_url` | `https://getgotak.com/maps/ATAK-Maps.zip` | Maps ZIP URL |

## Usage

```yaml
- hosts: opentakserver
  roles:
    - opentakserver-maps
```

Or run with tags:
```bash
ansible-playbook site.yml --tags ots-maps
```

## License

MIT
