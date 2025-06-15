local utils = import './utils.libsonnet';

local hosts = utils.hosts + {
  highgarden+: {
    ipv4_web: utils.hosts.mudgate.ipv4,
  },
};
local cf_proxy_setting(v) = { octodns: { cloudflare: { proxied: v } } };

local ensureEndDot(val) = if std.endsWith(val, '.') then val else val + '.';

local A(val) = {type: 'A', value: val} + cf_proxy_setting(false);
local AAAA(val) = {type: 'AAAA', value: val} + cf_proxy_setting(false);
local TXT(val) = {type: 'TXT', value: val};
local CNAME(val) = {type: 'CNAME', value: ensureEndDot(val)} + cf_proxy_setting(false);
local CNAME_CF_PROXY(val) = {type: 'CNAME', value: ensureEndDot(val)} + cf_proxy_setting(true);
local PTR(val) = {type: 'PTR', value: ensureEndDot(val) };
local MX(vals) = {type: 'MX', values: vals};
local NS(vals) = {type: 'NS', values: [ensureEndDot(val) for val in vals] };

local GMAIL_MX = MX([
  {exchange: 'aspmx.l.google.com.', preference: 1},
  {exchange: 'alt1.aspmx.l.google.com.', preference: 5},
  {exchange: 'alt2.aspmx.l.google.com.', preference: 5},
  {exchange: 'alt3.aspmx.l.google.com.', preference: 10},
  {exchange: 'alt4.aspmx.l.google.com.', preference: 10},
]);

# docker ipv6 address
local ipv6WebAddr(name) = std.strReplace(hosts[name].ipv6_prefix, ':/48', 'd0ce::6666');
local ipv6RdnsName(addr) = std.join('.', std.reverse(std.stringChars(std.strReplace(addr, ':', ''))));

local hostRules(name) = {
  [name]: A(hosts[name].ipv4),
  ['web.' + name]:
    [A(if std.objectHas(hosts[name], 'ipv4_web') then hosts[name].ipv4_web else hosts[name].ipv4)] +
    (if hosts[name].ipv6_prefix != null then [AAAA(ipv6WebAddr(name))] else []),
  ['*.' + name]: CNAME('web.' + name + '.blahgeek.com.'),
};

local ipv6CommonRdnsEntries(name, prefix_relative_to_zone='') = {
  # docker_subnet_id
  [ipv6RdnsName(prefix_relative_to_zone + 'd0ce:0000:0000:0000:6666')]:
    PTR('web.' + name + '.blahgeek.com'),
  [ipv6RdnsName(prefix_relative_to_zone + 'd0ce:0000:0000:0000:0001')]:
    PTR('docker-container.' + name + '.blahgeek.com'),
  [ipv6RdnsName(prefix_relative_to_zone + 'd0c0:0000:0000:0000:0001')]:
    PTR('docker-host.' + name + '.blahgeek.com'),
  # vpn_subnet_id
  [ipv6RdnsName(prefix_relative_to_zone + '1000:0000:0000:0000:0001')]:
    PTR('ovpn-server.' + name + '.blahgeek.com'),
  [ipv6RdnsName(prefix_relative_to_zone + '1000:0000:0000:0000:0002')]:
    PTR('ovpn-client.' + name + '.blahgeek.com'),

  [ipv6RdnsName(prefix_relative_to_zone + '1000:0000:0000:0000:1000')]:
    PTR('kissvpn-server.' + name + '.blahgeek.com'),
  [ipv6RdnsName(prefix_relative_to_zone + '1000:0000:0000:0000:1001')]:
    PTR('kissvpn-client.' + name + '.blahgeek.com'),
};

{
  'blahgeek.com.yaml': utils.manifestYaml({
    '': [
      A(hosts.highgarden.ipv4_web),
      GMAIL_MX,
      TXT('v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all'),
    ],

    'blog': CNAME('web.wall.blahgeek.com'),

    'wedding-photo': CNAME('iovip-z1.qiniuio.com'),
    'wedding-dev': CNAME_CF_PROXY('ffabb251-f5b7-4144-9148-07d032a4160e.cfargotunnel.com'),

    'www': A(hosts.highgarden.ipv4_web),

    '*.highgarden-v4': A(hosts.highgarden.ipv4_web),
    '*.highgarden-dyn': CNAME('blahgeek-highgarden.duckdns.org'),
    '*.highgarden-dyn-v4': CNAME('blahgeek-highgarden-v4.duckdns.org'),
    '*.highgarden-dyn-v6': CNAME('blahgeek-highgarden-v6.duckdns.org'),

    'qncdn.blog': CNAME('qncdn.blog.blahgeek.com.qiniudns.com'),
    'qncdn.hpurl': CNAME('idv0ypk.qiniudns.com'),
    'qndownload.blog': CNAME('qndownload-blog-blahgeek-com-idvh1ps.qiniudns.com'),
    'qnsource.hpurl': CNAME('iovip-z0.qbox.me'),

    // qiniu auth
    '_dnsauth.qnsource.hpurl': TXT('2022070701154107mculg4tn6wkyz7ia7n84wq2xy2wxgnlg1vdzq1ufao3i7qsr'),
    '_36010C22FBACF112943550BDCDE75424.qnsource.hpurl': CNAME('51F0713DB016BC7F5E647D460333923C.D9B55B23FD71EC50822B58C4A4D95730.cmcdt3vjd10mbk.trust-provider.com'),

    'dnspodcheck': TXT('70a8f523020ae061e3c2a4142fbbb1e1'),
    'google._domainkey': TXT('v=DKIM1\\; k=rsa\\; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmACHFeqUClWjUrUTp7izB56nNy7q9qFtnojQMKQ8MrdqqqBgxWrvJfNWP20DWgMmQ6MXCANRldfJ+zJMEbKoiHsMOVHTb/SApjh3Vj5ONvvcYjAIwPTrFoPu857JI+DHjIVkdP78xHiWB4P7lxFeo7ajt80ov47eKDHiCStfFLnhMfegt0Q2i44WO+kUWG5Dw" "qyTb3RORKds94/wjnm5NwLK288ZaGqPq9y9n5ok6ZS46rSRJvm+HjGASNT4BD2+y5XS7sc4xeTpebEnop9MpRtlr1QfNwHltnSjrpV7HCIPten52NsBYhpG7j4v+JsosssYjQ0wtscEkwNRYWaJsQIDAQAB'),

  } + std.foldr(function(a, b) a+b, [hostRules(x) for x in std.objectFields(hosts)], {})),

  'z1k.dev.yaml': utils.manifestYaml({
    '': [
      A(hosts['wall'].ipv4),
      AAAA(ipv6WebAddr('wall')),
      GMAIL_MX,
      TXT('v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all'),
    ],

    'share': CNAME('web.wall.blahgeek.com'),
    'google._domainkey': TXT('v=DKIM1\\; k=rsa\\; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnAPXEssA1Z1Js6uQ7kSGGbNj0N/vER3DygA/GnfIu6oILSUG/5XzSxIZN5t1qkdpwM3vKyMFmYzv0iDszl2PWeP0QDNVOIaMDweUAYZqt3DpoOmFuWNFZOLZs5V63AzpxeUcNQGXzttQFE7p2+TquM/Z3ZzSWggeSx/7MxesWy7taQbyjNuLTqArcAKwEitbqGg31hOJQ+YmByWHPEfPGzPRCIkUZbtSVkTJXefMGR0+252Tmo9KXDuhFnOfLZdPxnn7Tc3NPCbHbcfre2eqquCHWm1m65JEwSDcCxeRqqjgJSyIONxJKKZTY76xt8wNFRq3tMgGACfLfJWAsfWS4QIDAQAB'),
  }),

  [utils.ipv6RdnsZone(utils.yikai_net.home_prefix) + 'yaml']: utils.manifestYaml({
    [ipv6RdnsName('dead:0000:0000:0000:0001')]: PTR('highgarden.blahgeek.com'),
  }),

  [utils.ipv6RdnsZone(utils.yikai_net.usnet_prefix) + 'yaml']: utils.manifestYaml(
    {
      # straywarrior. prefix "a:" relative to usnet zone
      [ipv6RdnsName('a:0001:0000:0000:0000:0001')]: PTR('straywarrior-tunnel-server.eastwatch.blahgeek.com'),
      [ipv6RdnsName('a:0001:0000:0000:0000:0002')]: PTR('straywarrior-tunnel-client.eastwatch.blahgeek.com'),
    }
    + ipv6CommonRdnsEntries('eastwatch', prefix_relative_to_zone='2:')
  ),

  [utils.ipv6RdnsZone(utils.yikai_net.wall_prefix) + 'yaml']: utils.manifestYaml(
    ipv6CommonRdnsEntries('wall')
  ),
}
