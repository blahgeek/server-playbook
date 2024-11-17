# std.parseYaml does not support anchors.
local ansibleHostsYamlStr =
  std.strReplace(
    std.strReplace(importstr '../hosts.yml', "&my_hostvars", ""),
    "*my_hostvars",
    "null"
  ) ;

local ansibleHostsYaml = std.parseYaml(ansibleHostsYamlStr);
local commonWallVarsYaml = std.parseYaml(importstr '../roles/common-wall/vars/main.yml');

local hosts = {
  [std.split(item.key, '.')[0]]: {
    ipv4: item.value.ansible_host,
    ipv6_prefix: std.get(item.value, "ipv6_prefix"),
  }
  for item in std.objectKeysValues(ansibleHostsYaml.all.vars.my_hostvars)
};

{
  manifestYaml(obj):: std.manifestYamlDoc(obj, quote_keys=false),
  ipv6RdnsZone(network)::
    local parts = std.splitLimit(network, '/', 1);
    local prefixLen = std.parseInt(parts[1]);
    local chars = std.stringChars(std.strReplace(parts[0], ':', ''));
    std.join('.', std.reverse(std.slice(chars, 0, prefixLen / 4, 1))) + '.ip6.arpa.',

  hosts:: hosts,
  yikai_net:: commonWallVarsYaml.yikai_net + {
    [x + "_prefix"]: hosts[x].ipv6_prefix
    for x in std.objectFields(hosts)
    if std.objectHas(hosts[x], "ipv6_prefix")
  },
}
