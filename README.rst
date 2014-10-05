CloudHEP
========

Setup
-----

**Your S3 bucket name will probably need to be changed from the default.  
Below, it is assumed to be the default:** ``cloud-hep-testing-1`` 
**The user, group, policy and role names listed below are examples, but you 
probably don't need to change them**

CloudHEP uses the IAM identitiy management system to ensure that your CloudHEP work 
doesn't compromise the security of your other AWS work.  

First you must create a *role* for your EC2 nodes.  From the amazon web 
console, select the IAM service. Select the *Role* tab, and click 
*Create New Role*.  Name the role ``cloudhepnoderole``.  Then select 
*AWS Service Roles* -> *Amazon EC2*.  Then select *Custom Policy* -> *Select*.
Enter a policy name like ``cloudhepnodepolicy``, and copy paste
the following policy into the window, replacing ``cloud-hep-testing-1`` with your 
bucket name:

::

  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": ["arn:aws:s3:::cloud-hep-testing-1/*"]
      }
    ]
  }

Then create the role.  Note the role ARN (something like 
``arn:aws:iam::1234567890:role/cloudhepnoderole``), as you'll need it later.


Next, create a user, ``cloudhepsubmitter`` (skip making access keys 
for now), and a group, ``cloudhepsubmitters``.  From the user tab, you may add the user 
to the group.  Then, in the group tab, click on the group.  You can then click on 
*Attach Policy*, and then select *Custom Policy*.  Enter a policy name like 
``cloudhepsubmitterpolicy``, and copy paste the following policy into the window, 
replacing ``cloud-hep-testing-1`` with your bucket name and ``yourARNfornoderole`` with
the role ARN you noted earlier:

::

  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "s3:*",
        "Resource": ["arn:aws:s3:::cloud-hep-testing-1/*","arn:aws:s3:::cloud-hep-testing-1"]
      }
      {
        "Effect": "Allow",
        "Action": "ec2:*",
        "Resource": "*"
      }
      {
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "yourARNfornoderole"
      }
    ]
  }

Now, go to the user tab and select your user.  Click on *Manage Access Keys* and create
an access key.  Click *Show Security Credentials* and then copy the strings into the 
following lines of your ``~/.bashrc``:

::

  export AWS_ACCESS_KEY_ID=<replace with Acess Key ID>
  export AWS_SECRET_ACCESS_KEY=<replace with Secret Access Key>

Then, run ``source ~/.bashrc``.  From now on, you will be able to interact with the
EC2 service, and your shell and jobs should be able to interact with your S3 bucket.
