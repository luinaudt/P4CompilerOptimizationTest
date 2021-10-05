#include <core.p4>
#include <v1model.p4>
#include "includes/headers.p4"
#include "includes/constant.p4"


struct headers {
    ethernet_h          ethernet;
    vlan_h              vlan1;
    vlan_h              vlan2;
    mpls_h              mpls1;
    mpls_h              mpls2;
    ipv6_h              ipv6;
    ipv4_t              ipv4;
    icmp_h              icmp;
    icmp_h              icmp6;
    udp_h               udp;
    tcp_h               tcp;
}

struct metadata {
    /* empty */
}
//@Xilinx_MaxPacketRegion(1518*8)  // in bits
parser MyParser(packet_in pkt,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.type) {
	    0x0001            : parse_vlan2;
	    0x0002            : parse_mpls2;
	    0x0003            : parse_icmp;
	    0x0004            : parse_icmp6;
	    0x0005            : parse_tcp;
	    0x0006            : parse_udp;
	    0x8100 &&& 0xEFFF : parse_vlan1;
            0x0800            : parse_ipv4;
	    0x86DD            : parse_ipv6;
	    ETHERTYPE_MPLS    : parse_mpls1;
            default : accept;
        }
    }
    state parse_vlan1{
	pkt.extract(hdr.vlan1);
        transition select(hdr.vlan1.etherType) {
	    0x0001            : parse_vlan2;
	    0x0002            : parse_mpls2;
	    0x0003            : parse_icmp;
	    0x0004            : parse_icmp6;
	    0x0005            : parse_tcp;
	    0x0006            : parse_udp;
            0x0800            : parse_ipv4;
	    0x86DD            : parse_ipv6;
	    ETHERTYPE_MPLS    : parse_mpls1;
            default : accept;
        }
    }
    state parse_vlan2{
	pkt.extract(hdr.vlan2);
        transition select(hdr.vlan2.etherType) {
	    0x0002            : parse_mpls2;
	    0x0003            : parse_icmp;
	    0x0004            : parse_icmp6;
	    0x0005            : parse_tcp;
	    0x0006            : parse_udp;
            0x0800            : parse_ipv4;
	    0x86DD            : parse_ipv6;
	    ETHERTYPE_MPLS    : parse_mpls1;
            default : accept;
        }
    }
    
    state parse_mpls1{
	pkt.extract(hdr.mpls1);
	transition select(hdr.mpls1.label){
	    0            : parse_mpls2;
	    1            : parse_icmp;
	    2            : parse_icmp6;
	    3            : parse_tcp;
	    4            : parse_udp;
            5            : parse_ipv4;
	    6            : parse_ipv6;
	    default : accept;
	}
    }
    state parse_mpls2{
	pkt.extract(hdr.mpls2);
	transition parse_mpls_bos;
    }
    state parse_mpls_bos{
	transition select(pkt.lookahead<bit<4>>()){
	    1            : parse_icmp;
	    2            : parse_icmp6;
	    3            : parse_tcp;
	    4            : parse_udp;
            5            : parse_ipv4;
	    6            : parse_ipv6;
	    default : accept;
	}
    }
    state parse_ipv6 {
        pkt.extract(hdr.ipv6);
        transition select(hdr.ipv6.nh) {
	    1            : parse_icmp;
	    2            : parse_icmp6;
	    3            : parse_tcp;
	    4            : parse_udp;
            5            : parse_ipv4;
	    default : accept;
        }
    }
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
	    1            : parse_icmp;
	    2            : parse_icmp6;
	    3            : parse_tcp;
	    4            : parse_udp;
	    default : accept;
        }
    }
    state parse_icmp{
	pkt.extract(hdr.icmp);
	transition select(hdr.icmp.code) {
	    2            : parse_icmp6;
	    3            : parse_tcp;
	    4            : parse_udp;
	    default : accept;
        }
    }
    state parse_icmp6{
	pkt.extract(hdr.icmp6);
	transition select(hdr.icmp6.code) {
	    3            : parse_tcp;
	    4            : parse_udp;
	    default : accept;
        }
    }
    state parse_udp {
        pkt.extract(hdr.udp);
	transition select(hdr.udp.srcPort){
	    0: parse_tcp;
	    default : accept;
	}
    }
    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

}

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    apply {
    }
}


control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
    }
}

//@Xilinx_MaxPacketRegion(1518*8)  // in bits
control MyDeparser(packet_out pkt, in headers hdr) {
    apply {
	pkt.emit(hdr);
    }
}

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;