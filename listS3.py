#!/usr/bin/python

import argparse
import boto
import sys
import re

bucketName = "cloud-hep-testing-1"

parser = argparse.ArgumentParser(description="lists files in your S3 bucket")
parser.add_argument("-b","--bucket",help="S3 Bucket to connect to, default="+bucketName,default=bucketName)
parser.add_argument("-d","--dirsOnly",help="Only list directory names",action='store_true',default=False)
args = parser.parse_args()

bucketName = args.bucket

s3 = boto.connect_s3()
try:
  bucket = s3.get_bucket(bucketName)
except:
  print "Error: Bucket not found: "+bucketName
  sys.exit(1)

print("Bucket Name: "+bucketName)
if args.dirsOnly:
  dirList = set()
  for key in bucket.list():
    match = re.match(r"(.+)/.*",key.name)
    if match:
      dirName = match.group(1)
      if not (dirName in dirList):
        dirList.add(dirName)
  print("Directories: ")
  for key in sorted(list(dirList)):
    print("  {}".format(key))
else:
  for key in bucket.list():
    print("  {}".format(key.name))
