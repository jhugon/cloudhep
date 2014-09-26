#!/usr/bin/python

## Requires boto env var authentication
## Passes same authentication vars on to ec2 nodes

import os
import boto
from boto.s3.connection import Location
from boto.ec2.blockdevicemapping import BlockDeviceType
from boto.ec2.blockdevicemapping import BlockDeviceMapping

ec2 = boto.connect_ec2()

nRunning = 0
  
for res in ec2.get_all_instances():
  for ins in res.instances:
    if ins.state_code == 48:
      continue
    if ins.state_code == 16:
      nRunning += 1
    result = ""
    #result += str(ins.state_code)
    result += " "
    result += str(ins.id)
    result += " "
    result += str(ins.state)
    result += " "
    result += str(ins.public_dns_name)
    result += " | "
    if ins.tags.has_key("Name"):
      result += str(ins.tags["Name"])
      result += " "
    print(result)
print("N Running Instances: {0}".format(nRunning))
