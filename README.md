# ssh-proxy

Reach SSH hosts behind a proxy using SNI.

The script simplifies the connectivity to SSH hosts behind a proxy.

## Architecture

                    ┌───────────────────────────┐
                    │          Client           │
                    │     (On WAN or LAN)       │
                    └─────────────┬─────────────┘
                                  │
                    ┌─────────────▼─────────────┐
                    │       Proxy Server        │
                    │      (e.g. HAProxy)       │
                    └─────────────┬─────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
┌─────────▼─────────┐   ┌─────────▼─────────┐   ┌─────────▼─────────┐
│    SSH Target 1   │   │    SSH Target 2   │   │    SSH Target 3   │
│(SSH Host Machine) │   │(SSH Host Machine) │   │(SSH Host Machine) │
└───────────────────┘   └───────────────────┘   └───────────────────┘

## HAProxy Configuration Example

Detalis explained here: https://www.haproxy.com/blog/route-ssh-connections-with-haproxy.

The following snippets from a haproxy.cfg file will route SSH traffic to hosts:

```
...
resolvers dns-servers
   accepted_payload_size 8192
   nameserver dns1      1.2.3.4:53 # replace with real IP address
   nameserver dns2      1.2.3.5:53 # replace with real IP address
   resolve_retries      3
   timeout resolve      1s
   timeout retry        1s
   hold other           30s
   hold refused         30s
   hold nx              30s
   hold timeout         30s
   hold valid           10s
   hold obsolete        30s

##### HAPROXY SSH - BEGIN #####

# Connect to SSH via HAProxy using SNI passthrough
# The SSH client must support SNI (e.g. OpenSSH 7.3+)
# The SSH server must support SNI (e.g. OpenSSH 7.3+
# Example:
# ssh -o ProxyCommand="openssl s_client -quiet -connect [hostname_or_ip_of_proxy_server] -servername [ssh_host_to_connect_to]" [ssh_host_to_connect_to]

frontend frnd_ssh
    bind *:2222 ssl crt some_certificate_file.pem TODO: Replace with real certificate file(s)
    mode tcp and potentially change listening port
    option tcplog
    log-format "%ci:%cp [%t] %ft %b/%s %Tw/%Tc/%Tt %B %ts %ac/%fc/%bc/%sc/%rc %sq/%bq dstName:%[var(sess.dstName)] dstIP:%[var(sess.dstIP)] "

    tcp-request inspect-delay 5s
    acl valid_payload req.payload(0,7) -m str "SSH-2.0"
    tcp-request content reject if !valid_payload
    tcp-request content accept if { req_ssl_hello_type 1 }
    tcp-request content do-resolve(sess.dstIP,dns-servers,ipv4) ssl_fc_sni
    tcp-request content set-var(sess.dstName) ssl_fc_sni

    default_backend bknd_ssh_all

backend bknd_ssh_all
    mode tcp
    option tcplog

    acl allowed_destination var(sess.dst) -m ip 1.2.3.0/24 # TODO: Replace with real IP range
    acl allowed_server_names var(sess.dstName) -m str -i -- host1 host2 TODO: Replace host names with real host names

    tcp-request content set-dst var(sess.dstIP)

    tcp-request content accept if allowed_destination
    tcp-request content accept if allowed_server_names
    tcp-request content reject

    server ssh 0.0.0.0:22

##### HAPROXY SSH - END #####
...
```
