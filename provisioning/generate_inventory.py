#!/usr/bin/env python3
import argparse
import subprocess
import shlex
import os

BASE_INVENTORY = """\
all:
  hosts:
    {resource_group}-{vm_name}:
      ansible_ssh_common_args: '-F ./azure_ssh_config/ssh_config'
""".strip()


def get_vm_resource_group(vm_name, resource_group=None):
    if resource_group is None:
        resource_group = vm_name.replace("-vm", "-rg")
    return resource_group

def generate_ssh_config(vm_name, resource_group):
    ssh_config_dir = './azure_ssh_config'
    os.makedirs(ssh_config_dir, exist_ok=True)
    os.makedirs(os.path.join(ssh_config_dir, 'credentials'), exist_ok=True)

    cmd = f'az ssh config --overwrite --resource-group {resource_group} --vm-name {vm_name} ' \
          f'--file {ssh_config_dir}/ssh_config --keys-destination-folder {ssh_config_dir}/credentials'
    subprocess.run(shlex.split(cmd), check=True)

def generate_inventory_file(resource_group, vm_name):
    inventory_content = BASE_INVENTORY.format(resource_group=resource_group, vm_name=vm_name)
    with open('inventory.yml', 'w') as f:
        f.write(inventory_content)

def main():
    parser = argparse.ArgumentParser(description='Generate Ansible inventory for an Azure VM.')
    parser.add_argument('vm_name', help='The name of the Azure VM')
    parser.add_argument('--resource-group', help='The resource group of the Azure VM (optional)', default=None)
    args = parser.parse_args()

    resource_group = get_vm_resource_group(args.vm_name, args.resource_group)
    generate_ssh_config(args.vm_name, resource_group)
    generate_inventory_file(resource_group, args.vm_name)

if __name__ == "__main__":
    main()
