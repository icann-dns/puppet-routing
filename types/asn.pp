# This should really be a varrient of quagga and openbgpd 
# but we only have types in openbgpd
#type Routing::Asn = Openbgpd::Asn
type Routing::Asn = Integer[0, 4294967295]
