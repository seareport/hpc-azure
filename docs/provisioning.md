# Provisioning

## Dependency installation

## Authentication

```
az login --tenant 1647eb98-698c-4714-b3b5-8cc15f794d36
```

## Playbook execution

```
cd provisioning
rm -rf azure_ssh_config
python generate_inventory.py <VM_NAME>
ansible-playbook ping.yml
```
