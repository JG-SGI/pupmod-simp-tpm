# == Class: tpm::ima
#
# Sets up IMA kernel boot flags if they are not enabled, and mounts the
# securityfs when they are.
#
# == Parameters
#
# [*enable*]
#   Type: Boolean
#   Default: true
#     If true, enable IMA on the system.
#
# [*mount_dir*]
#   Where to mount ima securityfs
#
# [*ima_audit*]
#   Audit control.  Can be set to:
#     true  - Enable additional integrity auditing messages
#     false - Enable integrity auditing messages (default)
#
# [*ima_template*]
#   A pre-defined IMA measurement template format.
#   Can be one of ima, ima-ng, ima-sig. Defaults to ima-ng.
#
# [*ima_hash*]
#   Choose one of various hashes.  Defaults to sha1.
#   The list of supported hashes can be found in crypto/hash_info.h
#
# [*ima_tcb*]
#   Boolean. Toggle the TCB policy.  This means IMA will measure all
#   programs exec'd, files mmap'd for exec, and all file opened
#   for read by uid=0. Defaults to true.
#
# == Authors
#
# * Nick Markowski <namarkowski@keywcorp.com>
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class tpm::ima (
  $enable = true,
  $mount_dir = '/sys/kernel/security',
  $ima_audit = true,
  $ima_template = 'ima-ng',
  $ima_hash = 'sha1',
  $ima_tcb = true
){

  if $enable {
    if $::cmdline['ima'] == 'on' {

      mount { $mount_dir:
        ensure   => mounted,
        atboot   => true,
        device   => 'securityfs',
        fstype   => 'securityfs',
        target   => '/etc/fstab',
        remounts => true,
        options  => 'defaults',
        dump     => '0',
        pass     => '0'
      }
    }

    kernel_parameter { 'ima':
      value    => 'on',
      bootmode => 'normal'
    }

    kernel_parameter { 'ima_audit':
      value    => "$ima_audit",
      bootmode => 'normal'
    }

    kernel_parameter { 'ima_template':
      value    => $ima_template,
      bootmode => 'normal'
    }

    kernel_parameter { 'ima_hash':
      value    => $ima_hash,
      bootmode => 'normal'
    }

    if $ima_tcb {
      kernel_parameter { 'ima_tcb':
        notify => Reboot_notify['ima']
      }
    }
  }
  else {
    kernel_parameter { [ 'ima_tcb' ]:
      ensure => 'absent',
      notify => Reboot_notify['ima']
    }
    kernel_parameter { [ 'ima', 'ima_audit', 'ima_template', 'ima_hash' ]:
      ensure   => 'absent',
      bootmode => 'normal'
    }
  }

  reboot_notify { 'ima':
    subscribe => [
      Kernel_parameter['ima'],
      Kernel_parameter['ima_audit'],
      Kernel_parameter['ima_template'],
      Kernel_parameter['ima_hash']
    ]
  }

  validate_bool($ima_audit)
  validate_absolute_path($mount_dir)
  validate_array_member($ima_template, ['ima','ima-ng','ima-sig'])
  validate_bool($ima_tcb)
}
