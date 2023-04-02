local utils = import './utils.libsonnet';

local normalZoneConfig = {
  sources: ['config'],
  targets: ['cloudflare'],
};
local reverseZoneConfig = {
  sources: ['config'],
  targets: ['googlecloud'],
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
    'blahgeek.com.': normalZoneConfig,
    'z1k.dev.': normalZoneConfig,
    [utils.ipv6RdnsZone(utils.commonWallVarsYaml.yikai_net.eastwatch_prefix)]: reverseZoneConfig,
    [utils.ipv6RdnsZone(utils.commonWallVarsYaml.yikai_net.usnet_prefix)]: reverseZoneConfig,
  }
})
