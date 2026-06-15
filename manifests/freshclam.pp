# @summary Set up freshclam config and service.
#
# @param config_owner
#   Owner of the freshclam configuration file.
# @param config_group
#   Group that owns the freshclam configuration file.
# @param config_mode
#   File mode of the freshclam configuration file.
# @param sort_options
#   When true the configuration keys are written in alphabetical order.
#
class clamav::freshclam (
  String[1] $config_owner = 'root',
  String[1] $config_group = 'root',
  String[1] $config_mode  = '0644',
  Boolean   $sort_options = true,
) {
  if $clamav::freshclam_package {
    package { 'freshclam':
      ensure => $clamav::freshclam_version,
      name   => $clamav::freshclam_package,
      before => File['freshclam.conf'],
    }
  }

  # Ensure the database directory exists and is writable by the freshclam
  # user.  The package normally creates this, but ownership may be wrong
  # after upgrades or on distributions that changed the user's UID/GID
  # (e.g. RHEL 10 ships clamupdate with a different UID than RHEL 8/9).
  file { 'freshclam_db_dir':
    ensure => directory,
    path   => $clamav::freshclam_db_dir,
    owner  => $clamav::freshclam_db_owner,
    group  => $clamav::freshclam_db_group,
    mode   => '0755',
    before => File['freshclam.conf'],
  }

  file { 'freshclam.conf':
    ensure  => file,
    path    => $clamav::freshclam_config,
    mode    => $config_mode,
    owner   => $config_owner,
    group   => $config_group,
    content => epp('clamav/clamav.conf.epp', {
        config_options => $clamav::freshclam_options + { 'DatabaseMirror' => $clamav::freshclam_database_mirrors },
        sort_options   => $sort_options,
    }),
  }

  if $clamav::freshclam_sysconfig {
    file { 'freshclam_sysconfig':
      ensure  => file,
      path    => $clamav::freshclam_sysconfig,
      mode    => '0640',
      owner   => 'root',
      group   => 'root',
      content => epp('clamav/sysconfig/freshclam.epp', {
          freshclam_delay => $clamav::freshclam_delay,
      }),
    }

    $service_subscribe = [
      File['freshclam.conf'],
      File['freshclam_sysconfig'],
    ]
  } else {
    $service_subscribe = File['freshclam.conf']
  }

  # On RedHat < 8 freshclam runs via /etc/cron.daily/freshclam - no service.
  if $clamav::freshclam_service {
    service { 'freshclam':
      ensure     => $clamav::freshclam_service_ensure,
      name       => $clamav::freshclam_service,
      enable     => $clamav::freshclam_service_enable,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => $service_subscribe,
    }

    if $clamav::freshclam_package {
      Package['freshclam'] ~> Service['freshclam']
    }
  }
}
