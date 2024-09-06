# Entitlements cleanup test

## Usage

Create `activation-key` and `org-id` files with contents that allow activating `subscirption-manager`, then run

```bash
podman build -t entitlements-cleanup-test .

podman run --rm -it entitlements-cleanup-test
```

and examine files there (`/mnt/diff.*`).

## Findings

### Disclaimer: results are likely incomplete

* I certainly missed some things.
* This is point-in-time check and does not account for builds that were before and changes that will be in the future.

### PEM files

Deleted on unregistration (as long as a developer does not forget to do it).

A registered container has the following PEM files:

1. `/etc/pki/consumer/cert.pem`
2. `/etc/pki/consumer/key.pem`
3. `/etc/pki/entitlement/667276628584929350-key.pem` (or similar)
4. `/etc/pki/entitlement/667276628584929350.pem` (or similar)

Not sure what's the nature of `/etc/pki/consumer/cert.pem` and `/etc/pki/consumer/key.pem` but it's clear that mounting throw-away volume only for `/etc/pki/entitlement` isn't sufficient for the cases when engineers forget to unregister.

### syspurpose.json

Remains after unregistration.

```bash
cat entitled-uninstalled-unregistered/etc/rhsm/syspurpose/syspurpose.json
```

```json
{
  "role": "RHEL Server",
  "service_level_agreement": "Self-Support",
  "usage": "Development/Test"
}
```

Supposedly, the information was associated with the activation key and comes from the responsible service. It does not look like something we want to surprise customers when they discover. Also not sure if such containers will have supportability concerns.

There's also a doppelganger

```bash
cat registered/var/lib/rhsm/cache/syspurpose.json
```

```json
{
  "service_level_agreement": "Self-Support",
  "role": "RHEL Server",
  "usage": "Development/Test",
  "addons": []
}
```

which after unregistration becomes

```bash
cat unregistered/var/lib/rhsm/cache/syspurpose.json
{}
```

### productid_repo_mapping.json

Remains after unregistration.

This is one of the files which don't appear right away after `subscription-manager register ...` but only after subsequent usage of `dnf` (in my case to install a package).

The content looks like (redacted for brevity)

```bash
cat entitled-uninstalled/var/lib/rhsm/cache/productid_repo_mapping.json
```

```json
{"rhel-9-for-x86_64-appstream-rpms": "-----BEGIN CERTIFICATE-----\nMII[...]aLQ==\n-----END CERTIFICATE-----\n", "rhel-9-for-x86_64-baseos-rpms": "-----BEGIN CERTIFICATE-----\nMII[...]aLQ==\n-----END CERTIFICATE-----\n"}
```

Not sure how sensitive are the certificates, but looks suspicious.

### rhsm.log

The following appears upon container registration.

```bash
cat registered/var/log/rhsm/rhsm.log
```

```
2024-09-05 15:27:36,558 [INFO] subscription-manager:1:MainThread @managerlib.py:103 - Consumer created: 645809dd2ac3 (42a530f3-3288-4b35-835f-acb13e8cea44)
2024-09-05 15:27:54,202 [INFO] subscription-manager:1:MainThread @entcertlib.py:107 - certs updated:
Total updates: 1
Found (local) serial# []
Expected (UEP) serial# [667276628584929350]
Added (new)
  [sn:667276628584929350 ( Content Access,) @ /etc/pki/entitlement/667276628584929350.pem]
Deleted (rogue):
  <NONE>
2024-09-05 15:28:20,340 [INFO] subscription-manager:1:MainThread @register.py:241 - Unable to read rhsmcertd lock file: [Errno 2] No such file or directory: '/var/lock/subsys/rhsmcertd'
```

Looks relatively harmless but exposes some detail - serial number `667276628584929350`. Not sure how sensitive is that.

### content_access.json

Deleted on unregistration.

The contents are certificates in JSON. No idea how sensitive.

```bash
cat registered/var/lib/rhsm/cache/content_access.json
```

```json
{"lastUpdate": "2024-09-05T15:27:41+0000", "contentListing": {"667276628584929350": ["-----BEGIN CERTIFICATE-----\nMIIG[...]
```

### installed_products.json

Deleted on unregistration.

Whether or not the content is true for each container we ship is a question. Although seems relatively harmless.

```bash
cat registered/var/lib/rhsm/cache/installed_products.json
```

```json
{"products": {"479": {"productId": "479", "productName": "Red Hat Enterprise Linux for x86_64", "version": "9.4", "arch": "x86_64"}}, "tags": ["rhel-9-x86_64", "rhel-9"]}
```

### facts.json

Remains after unregistration.

```bash
cat registered/var/lib/rhsm/facts/facts.json
```

```json
{"system.certificate_version": "3.2", "virt.is_guest": true, "virt.host_type": "oci", "system.default_locale": "Unknown", "uname.sysname": "Linux", "uname.nodename": "6458[...]3", "uname.release": "5.15.0-118-lowlatency", "uname.version": "#128-Ubuntu SMP PREEMPT Wed Jul 17 14:35:21 UTC 2024", "uname.machine": "x86_64", "distribution.name": "Red Hat Enterprise Linux", "distribution.version": "9.4", "distribution.id": "Plow", "distribution.version.modifier": "", "memory.memtotal": "65508976", "memory.swaptotal": "2097148", "last_boot": "2024-08-28 07:32:22 UTC", "proc_cpuinfo.common.vendor_id": "GenuineIntel", "proc_cpuinfo.common.flags": "fpu vme de pse[...]
```

and so on and so forth, a lot of info about of the building machine including IP addresses. Info about kernel and CPU.
Maybe that's a feature, not a bug?

### redhat.repo

See

```bash
cat entitled-uninstalled/var/lib/rhsm/repo_server_val/redhat.repo
```

It mentions entitled keys (`/etc/pki/entitlement/667276628584929350*.pem`) a lot when registered. All mentions are erased on unregistration.
