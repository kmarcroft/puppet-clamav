# @summary Manage the clamonacc on-access scanner daemon.
#
# clamonacc is a separate process (introduced in ClamAV 0.102) that uses
# fanotify to intercept file-open events and submits them to clamd for
# scanning.  It must run as root to open the fanotify file descriptor, but
# passes already-open file descriptors to clamd (--fdpass) so that clamd
# itself does not need elevated privileges to read arbitrary files.
#
# This class creates a systemd unit file for clamonacc (the EPEL package does
# not ship one) and manages the service.  It is automatically contained when
# clamav::manage_on_access is true and clamav::clamd is in the catalogue.
#
# @param fdpass
#   Pass open file descriptors to clamd for scanning instead of the file path.
#   Required when clamd's User directive drops to a non-root account (the
#   default on RedHat: clamscan).  Without this clamd cannot open files owned
#   by other users and every scan returns "Access denied".
# @param service_ensure
#   Desired state of the clamonacc service.
# @param service_enable
#   Whether to enable the clamonacc service at boot.
#
class clamav::clamonacc (
  Boolean                 $fdpass         = true,
  Stdlib::Ensure::Service $service_ensure = 'running',
  Boolean                 $service_enable = true,
) {
  # Create a systemd unit file — the EPEL clamav package does not ship one.
  file { '/etc/systemd/system/clamonacc.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('clamav/clamonacc.service.epp', {
        config_file   => $clamav::clamd_config,
        clamd_service => $clamav::clamd_service,
        fdpass        => $fdpass,
    }),
  }

  # Subscribe to the unit file and, if clamd is also managed, to clamd.conf
  # so that clamonacc restarts whenever the on-access configuration changes.
  $subscribe_resources = $clamav::manage_clamd ? {
    true    => [File['/etc/systemd/system/clamonacc.service'], File['clamd.conf']],
    default => [File['/etc/systemd/system/clamonacc.service']],
  }

  service { 'clamonacc':
    ensure    => $service_ensure,
    enable    => $service_enable,
    subscribe => $subscribe_resources,
  }
}
