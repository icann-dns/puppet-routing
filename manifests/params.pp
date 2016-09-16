#
#
class routing::params {
  $daemon = $::kernel ? {
    'FreeBSD' => 'openbgpd',
    default   => 'quagga',
  }
}
