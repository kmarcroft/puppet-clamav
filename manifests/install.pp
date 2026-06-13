# @summary Installs the base ClamAV package.
class clamav::install {
  package { 'clamav':
    ensure => $clamav::clamav_version,
    name   => $clamav::clamav_package,
  }
}
