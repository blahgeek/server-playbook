local utils = import './utils.libsonnet';

local hosts = utils.hosts;

local CLOUDFLARE_NO_PROXY = { octodns: { cloudflare: { proxied: false } } };

local A(val) = {type: 'A', value: val} + CLOUDFLARE_NO_PROXY;
local AAAA(val) = {type: 'AAAA', value: val} + CLOUDFLARE_NO_PROXY;
local TXT(val) = {type: 'TXT', value: val};
local CNAME(val) = {type: 'CNAME', value: if std.endsWith(val, '.') then val else val + '.'} + CLOUDFLARE_NO_PROXY;
local MX(vals) = {type: 'MX', values: vals};

local GMAIL_MX = MX([
  {exchange: 'aspmx.l.google.com.', preference: 1},
  {exchange: 'alt1.aspmx.l.google.com.', preference: 5},
  {exchange: 'alt2.aspmx.l.google.com.', preference: 5},
  {exchange: 'alt3.aspmx.l.google.com.', preference: 10},
  {exchange: 'alt4.aspmx.l.google.com.', preference: 10},
]);

# docker ipv6 address
local ipv6WebAddr(name) = std.strReplace(hosts[name].ipv6_prefix, ':/48', 'd0ce::6666');

local hostRules(name) = {
  [name]: A(hosts[name].ipv4),
  ['web.' + name]:
    [A(hosts[name].ipv4)] +
    if hosts[name].ipv6_prefix != null then [AAAA(ipv6WebAddr(name))] else [],
  ['*.' + name]: CNAME('web.' + name + '.blahgeek.com.'),
};

{
  'blahgeek.com.yaml': utils.manifestYaml({
    '': [
      A(hosts['wall'].ipv4),
      GMAIL_MX,
      TXT('v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all'),
    ],

    'blog': CNAME('web.wall.blahgeek.com'),
    'www': CNAME('web.wall.blahgeek.com'),
    'mhome': CNAME('blahgeek-mhome.duckdns.org'),
    'xhome': CNAME('blahgeek-mhome.duckdns.org'),

    'qncdn.blog': CNAME('qncdn.blog.blahgeek.com.qiniudns.com'),
    'qncdn.hpurl': CNAME('idv0ypk.qiniudns.com'),
    'qndownload.blog': CNAME('qndownload-blog-blahgeek-com-idvh1ps.qiniudns.com'),
    'qnsource.hpurl': CNAME('iovip-z0.qbox.me'),

    '_dnsauth.qnsource.hpurl': TXT('2022070701154107mculg4tn6wkyz7ia7n84wq2xy2wxgnlg1vdzq1ufao3i7qsr'),
    'google._domainkey': TXT('v=DKIM1\\; k=rsa\\; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAmACHFeqUClWjUrUTp7izB56nNy7q9qFtnojQMKQ8MrdqqqBgxWrvJfNWP20DWgMmQ6MXCANRldfJ+zJMEbKoiHsMOVHTb/SApjh3Vj5ONvvcYjAIwPTrFoPu857JI+DHjIVkdP78xHiWB4P7lxFeo7ajt80ov47eKDHiCStfFLnhMfegt0Q2i44WO+kUWG5Dw" "qyTb3RORKds94/wjnm5NwLK288ZaGqPq9y9n5ok6ZS46rSRJvm+HjGASNT4BD2+y5XS7sc4xeTpebEnop9MpRtlr1QfNwHltnSjrpV7HCIPten52NsBYhpG7j4v+JsosssYjQ0wtscEkwNRYWaJsQIDAQAB'),

  } + std.foldr(function(a, b) a+b, [hostRules(x) for x in std.objectFields(hosts)], {})),

  'z1k.dev.yaml': utils.manifestYaml({
    '': [
      A(hosts['wall'].ipv4),
      AAAA(ipv6WebAddr('wall')),
      GMAIL_MX,
      TXT('v=spf1 include:_spf.mx.cloudflare.net include:_spf.google.com ~all'),
    ],

    'search': CNAME('web.wall.blahgeek.com'),
    'share': CNAME('web.wall.blahgeek.com'),

    'raven': MX([
      { exchange: 'eastwatch.blahgeek.com.', preference: 5 },
      { exchange: 'wall.blahgeek.com.', preference: 10 },
    ]),

    'google._domainkey': TXT('v=DKIM1\\; k=rsa\\; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnAPXEssA1Z1Js6uQ7kSGGbNj0N/vER3DygA/GnfIu6oILSUG/5XzSxIZN5t1qkdpwM3vKyMFmYzv0iDszl2PWeP0QDNVOIaMDweUAYZqt3DpoOmFuWNFZOLZs5V63AzpxeUcNQGXzttQFE7p2+TquM/Z3ZzSWggeSx/7MxesWy7taQbyjNuLTqArcAKwEitbqGg31hOJQ+YmByWHPEfPGzPRCIkUZbtSVkTJXefMGR0+252Tmo9KXDuhFnOfLZdPxnn7Tc3NPCbHbcfre2eqquCHWm1m65JEwSDcCxeRqqjgJSyIONxJKKZTY76xt8wNFRq3tMgGACfLfJWAsfWS4QIDAQAB'),
  }),
}
