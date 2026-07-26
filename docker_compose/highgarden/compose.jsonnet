std.manifestYamlDoc({
  version: "2",
  name: "composes",  // backward compatibility
  networks: {
    local config(ipv6_subnet) = {
      enable_ipv6: true,
      ipam: {
        config: [{subnet: ipv6_subnet}]
      }
    },

    // must all in :d0ce::/64, because only this range is forward to docker namespace
    // NOTE: the default docker network (outside of this compose project) uses ...:0001::/80 (in /etc/docker/daemon.json)

    // only :d0ce::/65 range is public (allow incoming connections), the upper half is not.
    // so containers with only "default" network will have a usable ipv6 address for outgoing connections (essential since nat64 is used for non-cn domains),
    // but is still not reachable from outside.
    "default": config("2a0e:aa07:e035:d0ce:8000::/80"),
    "external": config("2a0e:aa07:e035:d0ce::/80"),
  },
  // NOTE:
  // 1. The default network of this compose project is "default" (actually named "composes_default"),
  //    which is ipv4 only and essentially internal (without forwarding)
  //
  // 2. For public services,
  //    in ipv6 network, only serve in yikai-net (no nat or port expose required, use container's ip directly);
  //       (except tailproxy, which is special)
  //    in ipv4 network, serve from mudgate (via port forwarding)
  volumes: {
    "html": {},
    "certs": {},
    "acme": {},
    "prometheus-data": {},
    "grafana-data": {},
  },
  services: {

    local base(name) = {
      restart: "unless-stopped",
      container_name: name,
    },

    local network_external(ip=null) = {
      networks +: {
        "default": {},
        "external": {"gw_priority": 10} + (
          if std.isString(ip) then {"ipv6_address": ip} else {}
        ),
      },
    },

    local http_service(port, domain) = {   // port is a number; domain can be a comma-separated list of domains
      expose+: [std.toString(port)],
      environment+: [
        "VIRTUAL_HOST=" + domain,
        "VIRTUAL_PORT=" + std.toString(port),
        "LETSENCRYPT_HOST=" + domain,
      ],
    },

    "nginx-proxy":
      base("nginx-proxy") +
      network_external("2a0e:aa07:e035:d0ce::6666") + {
        image: "nginxproxy/nginx-proxy",
        environment+: [
          "ENABLE_IPV6=true"
        ],
        volumes+: [
          "html:/usr/share/nginx/html",
          "certs:/etc/nginx/certs:ro",
          "/var/run/docker.sock:/tmp/docker.sock:ro",
          "/var/docker-files/nginx-proxy/custom.conf:/etc/nginx/conf.d/custom.conf:ro"
        ],
        ports+: [
          "80:80",
          "443:443"
        ],
      },
    "acme-companion":
      base("nginx-proxy-acme") +
      network_external() + {
        image: "nginxproxy/acme-companion",
        environment+: [
          "DEFAULT_EMAIL=letsencrypt@blahgeek.com",
          "ACME_CHALLENGE=DNS-01",
          "ACMESH_DNS_API_CONFIG=" + std.manifestJsonMinified({
            "DNS_API": "dns_cf",
            "CF_Token": "${CLOUDFLARE_API_TOKEN}",
            "CF_Account_ID": "174ec50f32adc28bfcf27b9328d5308b",
          }),
        ],
        volumes_from+: [
          "nginx-proxy"
        ],
        volumes+: [
          "certs:/etc/nginx/certs:rw",
          "acme:/etc/acme.sh",
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ],
      },
    "whoami":
      base("whoami") +
      http_service(8000, "whoami.highgarden.blahgeek.com") + {
        image: "jwilder/whoami",
      },
    "beian-web":
      base("beian-web") +
      http_service(8000, "blahgeek.com,www.blahgeek.com") + {
        image: "blahgeek/beian-web:20251208",
      },
    // Forwarding path:
    // - for mudgate ipv4, it goes through mudate NAT64, forwarded to this container's ipv6 addr
    // - for yikai-net ipv6, no NAT
    // - for china-unicom ipv6, DNAT in highgarden, forwarded to this container's ipv6 addr
    // - for china-unicom ipv4, DNAT in highgarden, forwarded to 192.168.100.100
    //
    "tailproxy":
      base("tailproxy") +
      network_external("2a0e:aa07:e035:d0ce::9607") +
      // the http service is actually useless (virtual_port is not used), only the cert is used
      http_service(80,
                   std.join(",", [
                     "tailproxy.highgarden-dyn.blahgeek.com",
                     "tailproxy.highgarden-v4.blahgeek.com",
                     "tailproxy.highgarden-dyn-v4.blahgeek.com",
                     "tailproxy.highgarden-dyn-v6.blahgeek.com",
                   ])
                  ) + {
        image: "blahgeek/tailproxy:0.5",
        environment+: [
          "STUNNEL_CERT_DIR=/certs/tailproxy.highgarden-dyn.blahgeek.com/",
          "STUNNEL_LOCAL_PORT=:::8888",  // this binds both ipv6 and ipv4
          "STUNNEL_REMOTE=192.168.0.1:8889",
        ],
        volumes+: [
          "certs:/certs:ro"
        ],
        expose+: [
          "8888"
        ],
        ports+: [
          "8888:8888"
        ],
      },

    "smokeping":
      base("smokeping") +
      http_service(80, "smokeping.highgarden.blahgeek.com") + {
        image: "linuxserver/smokeping@sha256:d118c7100ded8ccfce7a2c66e0c1f00ce138b3b67eb42ef62e05bc4c57edfff1",
        volumes+: [
          "/var/docker-files/smokeping/data:/data",
          "/var/docker-files/smokeping/config:/config"
        ],
      },
    "inkstand-render-server":
      base("inkstand-render-server") +
      http_service(3000, "inkstand-render-server.highgarden.blahgeek.com") + {
        image: "blahgeek/inkstand-render-server:0.2",
        environment+: [
          "API_KEY=${INKSTAND_RENDER_SERVER_APIKEY}",
        ],
      },

    "prometheus":
      base("prometheus") +
      http_service(9090, "prometheus.highgarden.blahgeek.com") + {
        image: "prom/prometheus",
        volumes+: [
          "/var/docker-files/prometheus/:/etc/prometheus/",
          "prometheus-data:/prometheus",
        ],
        command: |||
          --config.file=/etc/prometheus/prometheus.yml
          --storage.tsdb.path=/prometheus
          --storage.tsdb.retention.time=1y
        |||,
      },
    "prometheus-json-exporter":
      base("prometheus-json-exporter") + {
        volumes+: [
          "/var/docker-files/prometheus-json-exporter/config.yml:/config.yml",
        ],
        image: "quay.io/prometheuscommunity/json-exporter",
        command: "--config.file=/config.yml",
      },
    "grafana":
      base("grafana") +
      http_service(3000, "grafana.highgarden.blahgeek.com") + {
        image: "grafana/grafana-oss",
        volumes+: [
          "grafana-data:/var/lib/grafana",
        ],
        // https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#configuration-options
        environment+: [
          "GF_DEFAULT_INSTANCE_NAME=highgarden",
        ],
      },

    "gdrive-webdav-proxy":
      base("gdrive-webdav-proxy") +
      http_service(8080, "gdrive-webdav-proxy.highgarden.blahgeek.com") + {
        image: "rclone/rclone:sha-fd1665a",
        volumes+: [
          "/var/docker-files/gdrive-webdav-proxy/rclone.conf:/rclone.conf",
        ],
        command: "--config /rclone.conf serve webdav --user blahgeek --pass ${GDRIVE_WEBDAV_PROXY_PASSWORD} --addr :8080 gdrive:Notes",
      },

    "vaultwarden":
      base("vaultwarden") +
      http_service(80, "vaultwarden.highgarden.blahgeek.com") + {
        image: "vaultwarden/server:1.37.0",
        volumes+: [
          "/var/docker-files/vaultwarden:/data",
        ],
        environment+: [
          "DOMAIN=https://vaultwarden.highgarden.blahgeek.com",
          "ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}",
        ],
      },

    "claw-gateway-proxy":
      base("claw-gateway-proxy") +
      http_service(80, "claw.highgarden.blahgeek.com") +
      {
        image: "pure/simple-reverse-proxy@sha256:9db95a52fb35ce6feb708fb1c45d4f3f670367da40d5f9d3ecf2281ccf892e1a",
        environment+: [
          "UPSTREAM=192.168.0.21:18789",
        ],
      }
  }
}, quote_keys=false, indent_array_in_object=true)
