#!/usr/bin/python

import sys
import os
import re
import argparse
import boto

bucketName = "cloud-hep-testing-1"

parser = argparse.ArgumentParser(description="Downloads a directory of files from S3, creating the same directory on disk.\n Will get from bucket named: '{0}'\n".format(bucketName))
parser.add_argument("dirname", help="Directory to download from S3, matches regular expressions")
parser.add_argument("-b","--bucket",help="S3 Bucket to connect to, default="+bucketName,default=bucketName)
parser.add_argument("-r","--retries", help="Number of retries on failed/invalid file download",type=float,default=5)
args = parser.parse_args()

bucketName = args.bucket
dirname = args.dirname
while dirname[0]=="/":
  dirname = dirname[1:]

needToMakeDir = False

if not os.path.exists(dirname):
  needToMakeDir = True
elif not os.path.isdir(dirname):
  print("Error: local path: "+dirname+" is not a directory")

s3 = boto.connect_s3()
try:
  bucket = s3.get_bucket(bucketName)
except:
  print("Error: Bucket "+bucketName+"not found, exiting.")
  sys.exit(1)

keyFound = False
for key in bucket.get_all_keys():
  if re.match(r"^"+dirname+"/.*",key.name):
    keyFound = True
    break

if not keyFound:
  print("Error: S3 Directory Not Found")
  sys.exit(1)

if needToMakeDir:
  os.makedirs(dirname)

for key in bucket.get_all_keys():
  if re.match(r"^"+dirname+"/.*",key.name):
    print("Getting file: "+key.name)
    remote_md5 = key.etag
    remote_md5 = remote_md5[1:len(remote_md5)-1]
    match_md5 = False
    iTry = 0
    while(not match_md5):
      key.get_contents_to_filename(key.name)

      tmpFile = open(key.name)
      local_md5 = boto.s3.key.compute_md5(tmpFile)
      local_md5 = local_md5[0]
      tmpFile.close()

      match_md5 = remote_md5 == local_md5
      #print("Debug md5:\nlocal:  {}\nremote: {}\nmatch: {}".format(local_md5,remote_md5,match_md5))

      iTry += 1
      if not match_md5:
        print("  MD5: local:  {}\n  remote: {}".format(local_md5,remote_md5))
        if iTry > args.retries:
          print("  Error: File integrity verification failed\n  maximum retries reached\n  deleting local file and going to next file!!")
          os.remove(key.name)
          break
        print("  Warning: File integrity verification failed; trying again...")
