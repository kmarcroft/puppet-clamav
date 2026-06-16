# Changelog

All notable changes to this project will be documented in this file.

## [4.0.2] - 2026-06-16  Kristian Marcroft

### New feature: `clamav::clamonacc` — managed clamonacc daemon

On-access scanning in ClamAV 0.102+ requires `clamonacc` as a **separate
process** (it is not part of `clamd`).  The EPEL package does not ship a
systemd unit for it.  When `manage_on_access => true`, Puppet now:

1. Creates `/etc/systemd/system/clamonacc.service` from an EPP template.
2. Manages the `clamonacc` service (enabled and running by default).
3. Ensures `clamd` starts before `clamonacc` (`Requires=` / `After=`).
4. Restarts `clamonacc` whenever `clamd.conf` or the unit file changes.

`--fdpass` is enabled by default so that `clamonacc` (running as root)
passes already-open file descriptors to `clamd` (running as `clamscan`/
`clamav`), avoiding *"Access denied"* errors on files owned by other users.

### New parameters
| Parameter | Default | Description |
|---|---|---|
| `clamonacc_fdpass` | `true` | Pass open FDs to clamd (`--fdpass`); required when clamd drops to a non-root user |
| `clamonacc_service_ensure` | `'running'` | Desired state of the clamonacc service |
| `clamonacc_service_enable` | `true` | Whether to enable clamonacc at boot |

---

## [4.0.1] - 2026-06-15  Kristian Marcroft

### Bug fixes
- **RHEL10 freshclam permission error** — `freshclam` failed with
  *"Can't create temporary directory /var/lib/clamav/tmp.*"* because
  RHEL10 assigns different UIDs/GIDs to the `clamupdate` user than
  RHEL8/9.  `clamav::freshclam` now manages `/var/lib/clamav` (or the
  path configured in `freshclam_db_dir`) as a Puppet file resource,
  ensuring it is always owned by the correct user before the service
  starts.
- **DatabaseMirror duplication** — setting `DatabaseMirror` inside the
  deep-merged `freshclam_options` hash caused the default mirror to be
  appended to rather than replaced.  `DatabaseMirror` is now a
  dedicated `freshclam_database_mirrors` parameter with normal
  first-wins Hiera merge semantics.

### New parameters
| Parameter | Default | Description |
|---|---|---|
| `freshclam_database_mirrors` | `['database.clamav.net']` | Replaces the mirror list; uses first-wins Hiera merge |
| `freshclam_db_dir` | `/var/lib/clamav` | Path to the ClamAV database directory |
| `freshclam_db_owner` | `clamupdate` (RedHat) / `clamav` (Debian) | User that must own the database directory |
| `freshclam_db_group` | `clamupdate` (RedHat) / `clamav` (Debian) | Group that must own the database directory |
| `manage_on_access` | `false` | Enable fanotify-based on-access scanning |
| `on_access_paths` | `['/']` | Paths monitored by the on-access scanner |
| `on_access_options` | see `data/common.yaml` | On-access clamd.conf directives (deep-merged) |

### Improvements
- On-access scanning defaults tuned for whole-system, detection-only
  operation with exclusions for pseudo-filesystems, remote mounts,
  container overlay storage, and snap mounts.

## [4.0.0] - 2026-06-13  Kristian Marcroft

### Breaking changes
- **Puppet requirement raised to >= 8.0.0** (OpenVox 8.x compatible); Puppet < 8 no longer supported
- **Dropped OS support:** Debian 11, Ubuntu 22.04, CentOS/RHEL 6 & 7
- **Added OS support:** RedHat/AlmaLinux/Rocky/OracleLinux 10, Debian 12 & 13, Ubuntu 24.04 & 26.04
- `clamav::params` class removed; all defaults now live in Hiera module data (`data/`)
- `inherits clamav::params` pattern removed from `clamav` class
- ERB templates replaced with EPP templates (`clamav.conf.epp`, `sysconfig/freshclam.epp`)
- `$module_name` variable replaced with literal `'clamav'` in EPP calls
- Resource titles in `clamav::user` changed to stable `clamav_group` / `clamav_user`
- `anchor` ordering pattern replaced with `contain` + ordering arrows

### New features
- All option hashes (`clamd_options`, `freshclam_options`, `clamav_milter_options`) are Hiera deep-merged
- OS-family Hiera data files: `data/RedHat.yaml`, `data/Debian.yaml`
- Hiera hierarchy extended with OS-family and OS-family/major-release levels
- GitHub Actions CI workflow (validate → unit tests → build/release on tag)

### Improvements
- Module renamed to `marckri-clamav`
- License identifier corrected to `GPL-3.0` (valid SPDX)
- `puppetlabs/stdlib` dependency pinned to `>= 9.0.0 < 10.0.0`
- Gemfile updated to Puppet 8 toolchain (`puppetlabs_spec_helper ~> 8.0`, `facterdb ~> 2.0`)
- RuboCop `TargetRubyVersion` updated to `3.1`
- Comprehensive RSpec unit tests covering all classes and both OS families
- `.gitignore` modernised; stale files removed (`.travis.yml`, `.sync.yml`, old acceptance tests)

## [3.0.0] - 2023-10-24  Frank Luo
- Update epel dependency

## [2.0.1] - Chris Edester
- PDK 1.18.1

## [2.0.0] - 2020-08-25  Chris Edester
- PDK support at 1.18.0
- Puppet 5/6 support
- Drop Puppet 3 support
- Update puppetlabs/stdlib dependency
- Switch to puppet/epel dependency

## [1.0.0] - 2016-08-10  Chris Edester
- Refactor private class params and specs
- RedHat 7.x support
- Manage /etc/sysconfig/freshclam on RedHat 7
- Comply with Puppet 4 strict variables

## 2014-10-29 (0.1.2)  Chris Edester
* puppet lint checks and improved version comparison

## 2014-09-15 (0.1.1)  Chris Edester
* compatability with puppet 3.7 and future parser

## 2014-07-01 (0.1.0)  Chris Edester
* Document and publish

## 2014-06-04 (0.0.7)  Chris Edester
* Debian config file options working

## 2014-06-04 (0.0.5)  Chris Edester
* RedHat config file options working

## 2014-06-04 (0.0.4)  Chris Edester
* Start work on config options

## 2014-06-02 (0.0.3)  Chris Edester
* Add user class and base templates

## 2014-06-02 (0.0.2)  Chris Edester
* Add clamd and freshclam classes

## 2014-05-30 (0.0.1)  Chris Edester
* Initial Commit of default files etc.
