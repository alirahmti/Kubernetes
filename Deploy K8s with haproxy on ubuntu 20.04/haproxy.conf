# Frontend for Kubernetes API
frontend k8s-api
  bind *:8443 # HAProxy listens on port 8443 for incoming traffic
  mode tcp
  option tcplog
  default_backend k8s-api

# Backend for Kubernetes API
backend k8s-api
  mode tcp
  option tcplog
  option tcp-check
  balance roundrobin
  default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
  server k8s-api-1 192.168.1.50:6443 check # Forwards traffic to the API server on port 6443 (Master Node IP Address)


# Monitoring HAProxy
frontend stats
  bind *:8404
  stats enable
  stats uri /stats
  stats refresh 10
