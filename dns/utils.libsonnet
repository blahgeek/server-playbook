local ansibleHostsYaml = std.parseYaml(importstr '../hosts.yml');
local commonWallVarsYaml = std.parseYaml(importstr '../roles/common-wall/vars/main.yml');

local hosts = {
  [std.split(hostname, '.')[0]]: {
    ipv4: ansibleHostsYaml.all.children[group].hosts[hostname].ansible_host,
    ipv6_prefix: std.get(commonWallVarsYaml.yikai_net, std.split(hostname, '.')[0] + '_prefix'),
  }
  for group in std.objectFields(ansibleHostsYaml.all.children)
  for hostname in std.objectFields(ansibleHostsYaml.all.children[group].hosts)
  if hostname != 'mhome.blahgeek.com'
};

{
  manifestYaml(obj):: std.manifestYamlDoc(obj, quote_keys=false),
  hosts: hosts,
}
