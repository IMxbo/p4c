/*
Copyright 2013-present Barefoot Networks,
Inc.

Licensed under the Apache License,
Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <core.p4>
#include <v1model.p4>

// IPv4 header without options
header ipv4_t {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      totalLen;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      fragOffset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdrChecksum;
    bit<32>      srcAddr;
    bit<32>      dstAddr;
}

struct H {
    ipv4_t inner_ipv4;
    ipv4_t ipv4;
}

struct M {}

parser P(packet_in b,
         out H p,
         inout M meta,
         inout standard_metadata_t standard_meta) {
    state start {
        transition accept;
    }
}

control Ing(inout H headers,
            inout M meta,
            inout standard_metadata_t standard_meta) {
    apply {}
}

control Eg(inout H hdrs,
           inout M meta,
           inout standard_metadata_t standard_meta) {
    apply {}
}

action drop() {}

control VerifyChecksumI(inout H hdr, inout M meta) {
    apply {
        verify_checksum(hdr.inner_ipv4.ihl == 5, {
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.totalLen,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.fragOffset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.srcAddr,
            hdr.inner_ipv4.dstAddr
        }, hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);

        verify_checksum(hdr.ipv4.ihl == 5, {
            // all ipv4 fields, except checksum itself
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr
        }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control ComputeChecksumI(inout H hdr, inout M meta) {
    apply {
        update_checksum(hdr.inner_ipv4.ihl == 5, {
            hdr.inner_ipv4.version,
            hdr.inner_ipv4.ihl,
            hdr.inner_ipv4.diffserv,
            hdr.inner_ipv4.totalLen,
            hdr.inner_ipv4.identification,
            hdr.inner_ipv4.flags,
            hdr.inner_ipv4.fragOffset,
            hdr.inner_ipv4.ttl,
            hdr.inner_ipv4.protocol,
            hdr.inner_ipv4.srcAddr,
            hdr.inner_ipv4.dstAddr
        }, hdr.inner_ipv4.hdrChecksum, HashAlgorithm.csum16);

        update_checksum(hdr.ipv4.ihl == 5, {
            // all ipv4 fields, except checksum itself
            hdr.ipv4.version,
            hdr.ipv4.ihl,
            hdr.ipv4.diffserv,
            hdr.ipv4.totalLen,
            hdr.ipv4.identification,
            hdr.ipv4.flags,
            hdr.ipv4.fragOffset,
            hdr.ipv4.ttl,
            hdr.ipv4.protocol,
            hdr.ipv4.srcAddr,
            hdr.ipv4.dstAddr
        }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

// deparser section
control DP(packet_out b, in H p) {
    apply {}
}

// Instantiate the top-level V1 Model package.
V1Switch(P(),
         VerifyChecksumI(),
         Ing(),
         Eg(),
         ComputeChecksumI(),
         DP()) main;
