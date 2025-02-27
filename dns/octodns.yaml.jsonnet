local utils = import './utils.libsonnet';

local zoneConfig = {
  sources: ['config'],
  targets: ['cloudflare'],
};

utils.manifestYaml({
  providers: {
    googlecloud: {
      class: 'octodns_googlecloud.GoogleCloudProvider',
      project: 'yikai-net',
    },
    cloudflare: {
      class: 'octodns_cloudflare.CloudflareProvider',
      token: 'env/CLOUDFLARE_API_TOKEN',
    },
    config: {
      class: 'octodns.provider.yaml.YamlProvider',
      directory: './config',
      default_ttl: 300,
      enforce_order: true,
    },
  },
  zones: {
    'blahgeek.com.': zoneConfig,
    'z1k.dev.': zoneConfig,
    [utils.ipv6RdnsZone(utils.yikai_net.home_prefix)]: zoneConfig,
    [utils.ipv6RdnsZone(utils.yikai_net.usnet_prefix)]: zoneConfig,
    [utils.ipv6RdnsZone(utils.yikai_net.wall_prefix)]: zoneConfig,
    [utils.ipv6RdnsZone(utils.yikai_net.whitetree_prefix)]: zoneConfig,
  }
})
