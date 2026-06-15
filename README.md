# clamav

[![CI](https://github.com/kmarcroft/puppet-clamav/actions/workflows/ci.yml/badge.svg)](https://github.com/kmarcroft/puppet-clamav/actions/workflows/ci.yml)
[![Puppet Forge](https://img.shields.io/puppetforge/v/marckri/clamav.svg)](https://forge.puppet.com/marckri/clamav)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/marckri/clamav.svg)](https://forge.puppet.com/marckri/clamav)

#### Table of Contents

1. [Overview](#overview)
2. [Usage](#usage)
3. [Configuration via Hiera](#configuration-via-hiera)
4. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)

## Overview

Puppet module to install and configure ClamAV and its components:

- Base `clamav` package (CLI tools and libraries)
- `clamd` daemon — package, config file, service
- `freshclam` daemon — package, config file, service
- `clamav-milter` — package, config file, service (optional)
- ClamAV system user/group (optional)

All configuration is driven by Hiera.  OS-appropriate defaults are
supplied by the module's own data layer (`data/RedHat.yaml`,
`data/Debian.yaml`) and can be overridden at any level of your own
hierarchy.

## Usage

### Minimal — install the ClamAV package only

```puppet
include clamav
```

### Enable clamd and freshclam

```puppet
class { 'clamav':
  manage_clamd     => true,
  manage_freshclam => true,
}
```

### All components with a custom user

```puppet
class { 'clamav':
  manage_user          => true,
  manage_clamd         => true,
  manage_freshclam     => true,
  manage_clamav_milter => true,
  uid                  => 499,
  gid                  => 499,
}
```

### Customise clamd and freshclam options

Values deep-merge across all Hiera levels, so you only need to supply
the keys you want to change.  `DatabaseMirror` is a dedicated parameter
with first-wins semantics so that overriding it replaces (rather than
appends to) the module default.

```puppet
class { 'clamav':
  manage_clamd     => true,
  manage_freshclam => true,
  clamd_options    => {
    'MaxScanSize' => '500M',
    'MaxFileSize' => '150M',
  },
  freshclam_options => {
    'HTTPProxyServer' => 'myproxy.example.com',
    'HTTPProxyPort'   => '8080',
  },
  # Replace (not append to) the default mirror list:
  freshclam_database_mirrors => [
    'clam1.example.com',
    'clam2.example.com',
  ],
}
```

### clamav-milter

```puppet
class { 'clamav':
  manage_clamd         => true,
  manage_freshclam     => true,
  manage_clamav_milter => true,
  clamd_options        => {
    'TCPSocket' => '3310',
    'TCPAddr'   => '127.0.0.1',
  },
  clamav_milter_options => {
    'AddHeader'  => 'Replace',
    'OnInfected' => 'Reject',
  },
}
```

### On-access scanning (whole-system, detection-only)

On-access scanning uses the Linux `fanotify` API to intercept file-open
events in real time.  It requires:

- A Linux kernel with `fanotify` support (all supported OS versions have this)
- The `clamd` daemon running as `root` initially (it drops privileges after the
  fanotify file descriptor is open, as controlled by the `User` directive)
- `manage_clamd => true`

The module defaults are tuned for whole-system, **detection-only** scanning
with exclusions that eliminate noise and remote-filesystem overhead:

```yaml
# Hiera — minimal addition to enable on-access scanning
clamav::manage_clamd:     true
clamav::manage_freshclam: true
clamav::manage_on_access: true
```

By default the scanner monitors `/` with the following path exclusions:

| Excluded path | Reason |
|---|---|
| `/proc`, `/sys`, `/dev`, `/run` | Kernel pseudo-filesystems — no real files |
| `/snap`, `/var/lib/snapd/snaps` | Signed, read-only squashfs loop mounts |
| `/var/lib/docker`, `/var/lib/containers`, `/var/lib/kubelet` | Container overlay layers — scanned at build/push time |
| `/nfs`, `/mnt`, `/media`, `/net` | Remote/removable filesystems — scan on the server side |

And the following performance safeguards are applied:

| Option | Value | Reason |
|---|---|---|
| `OnAccessPrevention` | `false` | Alert-only; blocking can cause deadlocks on false positives |
| `OnAccessMaxFileSize` | `5M` | Skip large files at open time; schedule scans cover them |
| `OnAccessExcludeRootUID` | `true` | Root can already read anything; skip its file events |
| `OnAccessDisableDDD` | `true` | Prevents re-scanning the same file via bind/overlay mounts |

#### Narrow the scan scope

If you want to scan only specific directories instead of `/`:

```yaml
clamav::on_access_paths:
  - '/home'
  - '/tmp'
  - '/var/www'
```

#### Enable blocking mode (prevention)

Only do this after thorough testing in detection-only mode.  A false
positive will deny legitimate file access:

```yaml
clamav::on_access_options:
  OnAccessPrevention: true
```

#### Add extra path exclusions

Option hashes are deep-merged, so add entries at any Hiera level:

```yaml
clamav::on_access_options:
  OnAccessExcludePath:
    - '/data/nfs'
    - '/var/backups'
```

## Configuration via Hiera

All class parameters can be set via Hiera.  Option hashes are
deep-merged, so you can layer overrides:

```yaml
# site Hiera — enable components
clamav::manage_clamd:     true
clamav::manage_freshclam: true

# tune clamd — merged on top of module defaults
clamav::clamd_options:
  MaxScanSize: '500M'
  MaxFileSize: '150M'
  ExcludePath:
    - '^/proc/'
    - '^/sys/'

# Replace the default database mirror (first-wins, not deep-merged):
clamav::freshclam_database_mirrors:
  - 'clam1.example.com'
  - 'clam2.example.com'

# tune other freshclam options (deep-merged):
clamav::freshclam_options:
  HTTPProxyServer: 'myproxy.example.com'
  HTTPProxyPort: '8080'
```

## Reference

See [REFERENCE.md](REFERENCE.md) for full parameter documentation
(generated by `bundle exec rake strings:generate:reference`).

### Classes

| Class | Description |
|---|---|
| `clamav` | Main entry point; all parameters live here |
| `clamav::install` | Installs the base ClamAV package |
| `clamav::user` | Manages the ClamAV system user and group |
| `clamav::clamd` | Manages the clamd package, config, and service |
| `clamav::freshclam` | Manages the freshclam package, config, and service |
| `clamav::clamav_milter` | Manages the clamav-milter package, config, and service |

## Limitations

Requires Puppet >= 8.0.0 (including OpenVox 8.x).

### Supported platforms

- RedHat / CentOS / AlmaLinux / Rocky / OracleLinux 8, 9, 10
- Debian 12, 13
- Ubuntu 24.04, 26.04

### Optional dependencies

On RedHat-family systems, setting `manage_repo => true` (the default for
RedHat) requires the [puppet/epel](https://forge.puppet.com/modules/puppet/epel)
module (`>= 4.0.0 < 7.0.0`) to be present in your environment.  
Debian/Ubuntu users, or RedHat users who manage EPEL by other means, can set
`manage_repo => false` and do not need this module.

## Development

Pull requests welcome. Please run the test suite before submitting:

```bash
bundle install
bundle exec rake validate   # syntax, lint, rubocop
bundle exec rake spec        # unit tests
```

## Credits

This module is a fork of [edestecd/puppet-clamav](https://github.com/edestecd/puppet-clamav).
Many thanks to everyone who contributed to the original project:

- **Chris Edester** ([@edestecd](https://github.com/edestecd)) — original author and long-time maintainer
- **Frank Luo** — epel dependency update
- **Daniel Rosenbloom** — fix for optional `$groups` parameter
- **Patrick Schönfeld** — supplementary group support for the ClamAV user

Their foundational work made this module possible.


#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with clamav](#setup)
    * [What clamav affects](#what-clamav-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with clamav](#beginning-with-clamav)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
7. [Contributors](#contributors)

## Overview

Puppet Module to install/configure clamd and freshclam on Debian and RedHat

## Module Description

The clamav module provides some classes to install and configure most of the components of clamav.  
You may also choose to manage only the parts that you need.  
This module aims to be minimalistic.  
No options produces stock config files as provided by your package installer.

This module has the following components that can be managed (or not):
* Base clamav package - command line and libs
* clamav user
* clam daemon
* freshclam daemon/cron (dependent on OS)
* clamav-milter (RHEL7 and derivatives only for now)

## Setup

### What clamav affects

* clamav/clamd/freshclam package install
* clamav/clamd/freshclam config files
* clamd/freshclam services or daily cron on redhat
* clamav-milter package install, config files, service (optional)
* clam user/group (optional)

### Setup Requirements

only need to install the module

### Beginning with clamav

Minimal clamav package install for command line use:

```puppet
include clamav
```

## Usage

### Manage the clam and freshclam daemon with stock config

```puppet
class { 'clamav':
  manage_clamd             => true,
  manage_freshclam         => true,
  clamd_service_ensure     => 'running',
  freshclam_service_ensure => 'stopped',
}
```

### Also manage the clam user and group

```puppet
class { 'clamav':
  manage_user      => true,
  uid              => 499,
  gid              => 499,
  shell            => '/sbin/nologin',
  manage_clamd     => true,
  manage_freshclam => true,
}
```

### Customize the clamd and freshclam config

```puppet
class { 'clamav':
  manage_clamd      => true,
  manage_freshclam  => true,
  clamd_options     => {
    'MaxScanSize' => '500M',
    'MaxFileSize' => '150M',
  },
  freshclam_options => {
    'LogTime'         => 'yes',
    'HTTPProxyServer' => 'myproxy.proxy.com',
    'HTTPProxyPort'   => '80',
    'NotifyClamd'     => '/etc/clamd.conf',
    'DatabaseMirror'  => [
      'clam.host1.mydomain.com',
      'clam.host2.mydomain.com',
    ],
  },
}
```

### Add clamav-milter support and customize its config (RHEL7 and derivatives only)
#### Please note that as of RHEL 7.2 only the TCP socket has been tested successfully

```puppet
class { 'clamav':
  manage_repo           => false,
  clamd_options         => {
    'TCPSocket' => '3310',
    'TCPAddr'   => '127.0.0.1',
  },

  clamav_milter_options => {
    'AddHeader'  => 'add',
    'OnInfected' => 'Reject',
    'RejectMsg'  => 'Message rejected: Infected by %v',
  },

  manage_clamd          => true,
  manage_freshclam      => true,
  manage_clamav_milter  => true,
  clamd_service_ensure  => 'running',
}
```

### Configure with hiera yaml

```puppet
include clamav
```
```yaml
---
clamav::manage_clamd: true
clamav::manage_freshclam: true

clamav::clamd_options:
  MaxScanSize: 500M
  MaxFileSize: 150M
clamav::freshclam_options:
  LogTime: yes
  HTTPProxyServer: myproxy.proxy.com
  HTTPProxyPort: 80
  NotifyClamd: /etc/clamd.conf
  DatabaseMirror:
  - clam.host1.mydomain.com
  - clam.host2.mydomain.com
```

## Reference

### Classes

* clamav
* clamav::user
* clamav::clamd
* clamav::freshclam

## Limitations

This module has been built on and tested against Puppet 3.8 and higher.  
While I am sure other versions work, I have not tested them.

This module supports modern RedHat and Debian based systems.  
No plans to support other versions (unless you add it :)..

## Development

Pull Requests welcome
