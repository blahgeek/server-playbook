local ansibleHostsYaml = std.parseYaml(importstr '../hosts.yml');
local commonWallVarsYaml = std.parseYaml(importstr '../roles/common-wall/vars/main.yml');

local hosts = {
  [std.split(hostname, '.')[0]]: {
    ipv4: ansibleHostsYaml.all.children[group].hosts[hostname].ansible_host,
    ipv6_prefix: std.get(commonWallVarsYaml.yikai_net, std.split(hostname, '.')[0] + '_prefix'),
  }
  for group in std.objectFields(ansibleHostsYaml.all.children)
  for hostname in std.objectFields(ansibleHostsYaml.all.children[group].hosts)
  if hostname != 'highgarden.blahgeek.com'
};

{
  manifestYaml(obj):: std.manifestYamlDoc(obj, quote_keys=false),
  ipv6RdnsZone(network)::
    local parts = std.splitLimit(network, '/', 1);
    local prefixLen = std.parseInt(parts[1]);
    local chars = std.stringChars(std.strReplace(parts[0], ':', ''));
    std.join('.', std.reverse(std.slice(chars, 0, prefixLen / 4, 1))) + '.ip6.arpa.',

  commonWallVarsYaml:: commonWallVarsYaml,
  hosts: hosts,
}
