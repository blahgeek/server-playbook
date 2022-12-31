set dotenv-load  # loading .env file

_list:
  @just --list

dns_render:
    jsonnet --string dns/octodns.yaml.jsonnet -o dns/octodns.yaml
    jsonnet --multi dns/config --string dns/config.jsonnet

# Run DNS sync, dry run
dns_sync: dns_render
    cd dns && pipenv run octodns-sync --config-file=octodns.yaml

# Run DNS sync
dns_sync_doit: dns_render
    cd dns && pipenv run octodns-sync --config-file=octodns.yaml --doit
