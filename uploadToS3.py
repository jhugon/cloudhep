#!/usr/bin/python

import argparse
import boto

bucketName = "cloud-hep-testing-1"
acl = "public-read"

parser = argparse.ArgumentParser(description="Uploads files to S3, with the same filename as the one on disk.\n Will put in bucket named: '{0}'\n With ACL: '{1}'\n Will also create a new bucket if above bucket doesn't exist".format(bucketName,acl))
parser.add_argument("filenames",nargs="+", help="Filename to upload to S3")
parser.add_argument("-b","--bucket",help="S3 Bucket to connect to, default="+bucketName,default=bucketName)
parser.add_argument("-p","--private",help="Makes file readable by only its owner", action="store_true", default=False)
parser.add_argument("-d","--dir", help="Directory to put file in S3 Bucket",default='')
parser.add_argument("-r","--retries", help="Number of retries on failed/invalid file upload",type=float,default=5)
args = parser.parse_args()

bucketName = args.bucket

if args.private:
  acl = "private"

s3 = boto.connect_s3()
try:
  bucket = s3.get_bucket(bucketName)
except:
  print "Creating new bucket: "+bucketName
  bucket = s3.create_bucket(bucketName)
for fn in args.filenames:
  #Get md5
  tmpFile = open(fn)
  local_md5 = boto.s3.key.compute_md5(tmpFile)
  local_md5 = local_md5[0]
  tmpFile.close()
  match_md5 = False
  iTry = 0
  while(not match_md5):
    print("Copying {0}\n  to {1}\n  in bucket {2}\n  ACL: {3}".format(fn,args.dir+'/'+fn,bucketName,acl))
    key = bucket.new_key(args.dir+'/'+fn)
    key.set_contents_from_filename(fn)
    key.set_acl(acl)
    # Check that file is valid
    remote_md5 = key.etag
    remote_md5 = remote_md5[1:len(remote_md5)-1]
    match_md5 = remote_md5 == local_md5
    #print("Debug md5:\nlocal:  {}\nremote: {}\nmatch: {}".format(local_md5,remote_md5,match_md5))
    iTry += 1
    if not match_md5:
      print("  MD5: local:  {}\n  remote: {}".format(local_md5,remote_md5))
      if iTry > args.retries:
        print("  Error: File integrity verification failed\n  maximum retries reached\n  deleting key and going to next file!!")
        key.delete()
        break
      print("  Warning: File integrity verification failed; trying again...")
  
