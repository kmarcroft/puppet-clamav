# @summary Manage ClamAV antivirus and its components
#
# All parameters default to OS-appropriate values supplied via the module's
# own Hiera data.  Override any of them in your own Hiera hierarchy to
# customise the installation.
#
# @param manage_user
#   Whether to manage the ClamAV user and group (packages create them by default).
# @param manage_repo
#   Whether to include the puppet/epel class to enable EPEL (RedHat family only).
# @param manage_clamd
#   Whether to manage the clamd daemon package, config and service.
# @param manage_freshclam
#   Whether to manage freshclam package, config and service.
# @param manage_clamav_milter
#   Whether to manage clamav-milter package, config and service.
# @param clamav_package
#   Name of the base ClamAV package.
# @param clamav_version
#   Ensure value for the base ClamAV package.
# @param user
#   ClamAV system user name.
# @param comment
#   GECOS comment for the ClamAV user.
# @param uid
#   UID for the ClamAV user.
# @param gid
#   GID for the ClamAV group.
# @param home
#   Home directory for the ClamAV user.
# @param shell
#   Shell for the ClamAV user.
# @param group
#   ClamAV system group name.
# @param groups
#   Additional supplementary groups for the ClamAV user.
# @param clamd_package
#   Name of the clamd package.
# @param clamd_version
#   Ensure value for the clamd package.
# @param clamd_config
#   Absolute path to the clamd configuration file.
# @param clamd_service
#   Name of the clamd service.
# @param clamd_service_ensure
#   Desired state of the clamd service.
# @param clamd_service_enable
#   Whether to enable the clamd service at boot.
# @param clamd_options
#   Hash of clamd configuration key/value pairs.  Values may be arrays for
#   directives that accept multiple entries.  Deep-merged across Hiera levels.
# @param freshclam_package
#   Name of the freshclam package (undef if provided by the base package).
# @param freshclam_version
#   Ensure value for the freshclam package.
# @param freshclam_config
#   Absolute path to the freshclam configuration file.
# @param freshclam_service
#   Name of the freshclam service (undef if using cron instead).
# @param freshclam_service_ensure
#   Desired state of the freshclam service.
# @param freshclam_service_enable
#   Whether to enable the freshclam service at boot.
# @param freshclam_options
#   Hash of freshclam configuration key/value pairs.  Deep-merged across Hiera levels.
# @param freshclam_sysconfig
#   Absolute path to the freshclam sysconfig file (RedHat only, undef on Debian).
# @param freshclam_delay
#   FRESHCLAM_DELAY value written to the sysconfig file.
# @param clamav_milter_package
#   Name of the clamav-milter package.
# @param clamav_milter_version
#   Ensure value for the clamav-milter package.
# @param clamav_milter_config
#   Absolute path to the clamav-milter configuration file.
# @param clamav_milter_service
#   Name of the clamav-milter service.
# @param clamav_milter_service_ensure
#   Desired state of the clamav-milter service.
# @param clamav_milter_service_enable
#   Whether to enable the clamav-milter service at boot.
# @param clamav_milter_options
#   Hash of clamav-milter configuration key/value pairs.  Deep-merged across Hiera levels.
#
class clamav (
  Boolean                        $manage_user                  = false,
  Boolean                        $manage_repo                  = false,
  Boolean                        $manage_clamd                 = false,
  Boolean                        $manage_freshclam             = false,
  Boolean                        $manage_clamav_milter         = false,

  String[1]                      $clamav_package               = 'clamav',
  String[1]                      $clamav_version               = 'installed',

  Optional[String[1]]            $user                         = undef,
  Optional[String]               $comment                      = undef,
  Optional[Integer[0]]           $uid                          = undef,
  Optional[Integer[0]]           $gid                          = undef,
  Optional[Stdlib::Absolutepath] $home                         = undef,
  Optional[Stdlib::Absolutepath] $shell                        = undef,
  Optional[String[1]]            $group                        = undef,
  Optional[Array[String[1]]]     $groups                       = undef,

  String[1]                      $clamd_package                = 'clamd',
  String[1]                      $clamd_version                = 'installed',
  Stdlib::Absolutepath           $clamd_config                 = '/etc/clamd.d/scan.conf',
  String[1]                      $clamd_service                = 'clamd',
  Stdlib::Ensure::Service        $clamd_service_ensure         = 'running',
  Boolean                        $clamd_service_enable         = true,
  Hash[String[1], NotUndef]      $clamd_options                = {},

  Optional[String[1]]            $freshclam_package            = undef,
  Optional[String[1]]            $freshclam_version            = undef,
  Stdlib::Absolutepath           $freshclam_config             = '/etc/freshclam.conf',
  Optional[String[1]]            $freshclam_service            = undef,
  Stdlib::Ensure::Service        $freshclam_service_ensure     = 'running',
  Boolean                        $freshclam_service_enable     = true,
  Hash[String[1], NotUndef]      $freshclam_options            = {},
  Optional[Stdlib::Absolutepath] $freshclam_sysconfig          = undef,
  Optional[String]               $freshclam_delay              = undef,

  Optional[String[1]]            $clamav_milter_package        = undef,
  Optional[String[1]]            $clamav_milter_version        = undef,
  Optional[Stdlib::Absolutepath] $clamav_milter_config         = undef,
  Optional[String[1]]            $clamav_milter_service        = undef,
  Stdlib::Ensure::Service        $clamav_milter_service_ensure = 'running',
  Boolean                        $clamav_milter_service_enable = true,
  Hash[String[1], NotUndef]      $clamav_milter_options        = {},
) {
  if $manage_repo {
    include epel
  }

  contain clamav::install

  if $manage_user {
    contain clamav::user
    Class['clamav::user'] -> Class['clamav::install']
  }

  if $manage_clamd {
    contain clamav::clamd
    Class['clamav::install'] -> Class['clamav::clamd']
  }

  if $manage_freshclam {
    contain clamav::freshclam
    Class['clamav::install'] -> Class['clamav::freshclam']
  }

  if $manage_clamav_milter {
    contain clamav::clamav_milter
    Class['clamav::install'] -> Class['clamav::clamav_milter']
  }
}
