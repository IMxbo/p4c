#include <core.p4>
#include <ebpf_model.p4>

typedef bit<48> EthernetAddress;
typedef bit<32> IPv4Address;
header IPv4_h {
    bit<4>      version;
    bit<4>      ihl;
    bit<8>      diffserv;
    bit<16>     totalLen;
    bit<16>     identification;
    bit<3>      flags;
    bit<13>     fragOffset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     hdrChecksum;
    IPv4Address srcAddr;
    IPv4Address dstAddr;
}

extern bool verify_ipv4_checksum(in IPv4_h iphdr);
header Ethernet_h {
    EthernetAddress dstAddr;
    EthernetAddress srcAddr;
    bit<16>         etherType;
}

struct Headers_t {
    Ethernet_h ethernet;
    IPv4_h     ipv4;
}

parser prs(packet_in p, out Headers_t headers) {
    state start {
        p.extract<Ethernet_h>(headers.ethernet);
        p.extract<IPv4_h>(headers.ipv4);
        transition accept;
    }
}

control pipe(inout Headers_t headers, out bool pass) {
    bool verified_0;
    @hidden action ebpf_checksum_extern57() {
        verified_0 = verify_ipv4_checksum(headers.ipv4);
        pass = verified_0;
    }
    @hidden table tbl_ebpf_checksum_extern57 {
        actions = {
            ebpf_checksum_extern57();
        }
        const default_action = ebpf_checksum_extern57();
    }
    apply {
        tbl_ebpf_checksum_extern57.apply();
    }
}

ebpfFilter<Headers_t>(prs(), pipe()) main;
