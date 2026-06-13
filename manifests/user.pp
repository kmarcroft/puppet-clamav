# @summary Manage the ClamAV system user and group.
#
# Manages the user/group only when the parent class parameter
# manage_user is true AND the relevant user/group name is set.
#
class clamav::user {
  if $clamav::group {
    group { 'clamav_group':
      ensure => present,
      name   => $clamav::group,
      gid    => $clamav::gid,
      system => true,
    }
  }

  if $clamav::user {
    user { 'clamav_user':
      ensure  => present,
      name    => $clamav::user,
      comment => $clamav::comment,
      uid     => $clamav::uid,
      gid     => $clamav::gid,
      groups  => $clamav::groups,
      home    => $clamav::home,
      shell   => $clamav::shell,
      system  => true,
    }

    if $clamav::group {
      Group['clamav_group'] -> User['clamav_user']
    }
  }
}
