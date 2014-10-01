#!/usr/bin/python
# -*- coding: utf-8 -*-
DOCUMENTATION = '''
---
module: win_hostname
version_added: "1.8"
short_description: Changes the hostname of a windows machine
description:
	- Changes the Hostname of a windows machine
options:
  name:
    description:
	  - New Hostname of the windows machine 
	  required: true
	  default: null
	  aliases: []
  restart:
    description:
	  - Restart after name change
	required: false
	choices:
	- yes
	- no
	default: null
	aliases: []
author: Nic O'Connor
'''

EXAMPLE = '''
#Change the hostname of a windows machine
$ansible -i hosts -m win_hostname -a "name=test restart=yes" windows

#Hosts File Example
#This playbook is great if you have an inventory of IP addresses and want to set the hostname 
#[windows]
#DC-01 ansible_ssh_host=192.168.33.10

#Playbook example 
---
- name: Change Hostname 
  hosts: windows
  gather_facts: false
  tasks:
    - name: Module Change Hostname
      win_hostname:
        name: "{{inventory_hostname_short}}"
        restart: yes
'''