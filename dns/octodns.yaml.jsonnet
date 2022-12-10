local utils = import './utils.libsonnet';

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
    [x]: {
      sources: ['config'],
      targets: ['googlecloud', 'cloudflare'],
    }
    for x in ['blahgeek.com.', 'z1k.dev.']
  }
})
