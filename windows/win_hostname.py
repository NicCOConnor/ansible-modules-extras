#!/usr/bin/python
# -*- coding: utf-8 -*-
DOCUMENTATION = '''
---
module: win_hostname
version_added: "2.0"
short_description: Changes the hostname of a windows machine optionally adds or removes from a domain
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
	  - Restart when done.
	required: false
	choices:
	- yes
	- no
	default: null
	aliases: []
  domain:
    description:
      - When specified will join a computer to the domain, requires domain_user and domain_pass
    required: false
    default: null
    aliases: []
  workgroup:
    description:
    - When specified will change the workgroup of a computer, if added to a domain it will remove the 
      computer from the domain, cannot be specified with domain
    required: false
    default: null
    aliases: []
  domain_user:
    description:
      - Domain user that has permissions to add computers to the domain, required if domain or workgroup is specified
    required: false
    default: null
    aliases: []
  domain_pass:
    description:
      - Password for domain_user, required if domain or workgroup is specified
    required: false
    default: null
    aliases: []
  
author: Nic O'Connor


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
        
- name: Change Hostname and add to domain
  win_hostname:
    name: "{{inventory_hostname_short}}"
    domain: "testing.com"
    domain_user: Administrator
    domain_pass: testing123
    restart: yes

- name: Remove Computer from domain
    name: {{inventory_hostname_short}}
    workgroup: WORKGROUP
    domain_user: Administrator
    domain_pass: testing123
    restart: yes
'''
