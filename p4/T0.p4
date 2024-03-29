
#include <core.p4>
#include <v1model.p4>
#include "includes/headers.p4"


header tunnel_h{bit<32> id;}

struct headers {
    ethernet_h          ethernet;
    tunnel_h            tunnel;
    ipv4_h              ipv4;
    tcp_h               tcp; }
struct metadata {
    /* empty */
}
//@Xilinx_MaxPacketRegion(1518*8)  // in bits
parser MyParser(packet_in Pkt_in,
                out headers PHV,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start { 
        Pkt_in.extract(PHV.ethernet);
        transition select(PHV.ethernet.type) {
            0x800  : parse_ipv4;
            5 : parse_tunnel;
            default : accept; 
        } 
    }
    state parse_ipv4 { 
        Pkt_in.extract(PHV.ipv4);
        transition select(PHV.ipv4.protocol) {
            6       : parse_tcp;
            default : accept;
        } 
    }
    state parse_tunnel {Pkt_in.extract(PHV.tunnel); 
        transition accept;
    }
    state parse_tcp { Pkt_in.extract(PHV.tcp);
        transition accept; 
    }
}  

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}

control MyIngress(inout headers PHV,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action encapsulate(bit<32> id){
        PHV.tunnel.setValid(); 
        PHV.tunnel.id=id; 
        PHV.ethernet.type = 5;}
    action forward(bit<48> dstAddr) {
        PHV.ethernet.src = PHV.ethernet.dst;
        PHV.ethernet.dst = dstAddr; }
    table ipv4_lpm {
        key = { PHV.ipv4.dstAddr: lpm;}
        actions = {forward; encapsulate;}
        size = 1024;
        default_action = forward(0); 
    }
    apply { 
        ipv4_lpm.apply(); 
    } 
} 


control MyEgress(inout headers PHV,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
    }
}

//@Xilinx_MaxPacketRegion(1518*8)  // in bits
control MyDeparser(packet_out Pkt_out, in headers PHV) {
    apply {
       Pkt_out.emit(PHV.ethernet );
       Pkt_out.emit(PHV.tunnel );
       Pkt_out.emit(PHV.ipv4);
       Pkt_out.emit(PHV.tcp); 
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