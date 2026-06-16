# @summary Set up clamd config and service.
#
# @param sort_options
#   When true the configuration keys are written in alphabetical order.
#
class clamav::clamd (
  Boolean $sort_options = true,
) {
  # When on-access scanning is requested, merge the on-access paths and options
  # on top of the base clamd options so they land in clamd.conf together.
  #
  # OnAccessMountPath is used for mount points (including '/') — it hooks
  # fanotify at the VFS mount level and works with DDD enabled.
  # OnAccessIncludePath is used for specific subdirectories only.
  # Using OnAccessIncludePath '/' with DDD enabled is explicitly rejected by
  # clamonacc with: "Please use the OnAccessMountPath option to watch '/'"
  if $clamav::manage_on_access {
    $oa_mount_hash = $clamav::on_access_mount_paths.empty ? {
      true    => {},
      default => { 'OnAccessMountPath' => $clamav::on_access_mount_paths },
    }
    $oa_path_hash  = $clamav::on_access_paths.empty ? {
      true    => {},
      default => { 'OnAccessIncludePath' => $clamav::on_access_paths },
    }
    $effective_options = $clamav::clamd_options + $oa_mount_hash + $oa_path_hash + $clamav::on_access_options
  } else {
    $effective_options = $clamav::clamd_options
  }

  package { 'clamd':
    ensure => $clamav::clamd_version,
    name   => $clamav::clamd_package,
    before => File['clamd.conf'],
  }

  file { 'clamd.conf':
    ensure  => file,
    path    => $clamav::clamd_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('clamav/clamav.conf.epp', {
        config_options => $effective_options,
        sort_options   => $sort_options,
    }),
  }

  service { 'clamd':
    ensure     => $clamav::clamd_service_ensure,
    name       => $clamav::clamd_service,
    enable     => $clamav::clamd_service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => [Package['clamd'], File['clamd.conf']],
  }
}
