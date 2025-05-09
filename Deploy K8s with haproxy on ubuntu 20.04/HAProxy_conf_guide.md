### 🌟 HAProxy Configuration Guide 🌟

#### 📝 **Introduction**
HAProxy (**High Availability Proxy**) is a powerful, open-source **TCP/HTTP load balancer** and proxying solution. It is widely used to enhance the **performance** and **reliability** of server environments by distributing workloads across multiple servers. HAProxy is trusted by major platforms like **GitHub**, **Instagram**, and **Twitter** for its robustness and efficiency .

---

#### 🛠️ **Installation**
To install HAProxy on **Ubuntu**, follow these steps:

1. **Update your package list**:
   ```bash
   sudo apt update
   ```
2. **Install HAProxy**:
   ```bash
   sudo apt install haproxy
   ```
   ✅ **Done!** HAProxy is now installed.

3. **Edit the configuration file**:
   ```bash
   sudo vim /etc/haproxy/haproxy.cfg
   ```

---

#### ⚙️ **HAProxy Configuration**
The HAProxy configuration file is divided into **four essential sections**: `global`, `defaults`, `frontend`, and `backend`. Each section plays a specific role in defining how HAProxy operates .

---

### 🧩 **Key Configuration Sections**

#### 1️⃣ **Global Section**
The `global` section contains process-wide settings that affect HAProxy's performance and security. Example:
```haproxy
global
    log /dev/log local0
    maxconn 50000
    user haproxy
    group haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
```
- **`log`**: Defines where logs are sent.
- **`maxconn`**: Sets the maximum number of concurrent connections.
- **`user`/`group`**: Drops privileges after initialization for security.
- **`stats socket`**: Enables runtime API for monitoring and dynamic configuration.

---

#### 2️⃣ **Defaults Section**
The `defaults` section defines default settings for all `frontend` and `backend` sections below it. Example:
```haproxy
defaults
    mode http
    timeout connect 5s
    timeout client 10s
    timeout server 10s
    log global
    option httplog
```
- **`mode`**: Defines the operating mode (`http` or `tcp`).
- **`timeout`**: Sets connection timeouts to prevent deadlocks.
- **`log global`**: Uses the global logging configuration.
- **`option httplog`**: Enables detailed HTTP logging.

---

#### 3️⃣ **Frontend Section**
The `frontend` section defines how clients connect to HAProxy. Example:
```haproxy
frontend k8s-api
    bind *:8443
    mode tcp
    option tcplog
    default_backend k8s-api
```
- **`bind`**: Specifies the IP and port HAProxy listens on.
- **`mode`**: Defines the mode (`tcp` in this case).
- **`default_backend`**: Links this frontend to a backend.

---

#### 4️⃣ **Backend Section**
The `backend` section defines the pool of servers that handle client requests. Example:
```haproxy
backend k8s-api
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server k8s-api-1 192.168.168.51:6443 check
```
- **`balance`**: Load balancing algorithm (e.g., `roundrobin`, `leastconn`).
- **`server`**: Defines backend servers with IP, port, and health check options.

---

#### 📊 **Monitoring HAProxy**
HAProxy includes a built-in **monitoring dashboard** to track performance and health.

Add the following to your configuration:
```haproxy
frontend stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 10
```
- **`bind`**: Exposes the monitoring dashboard on port `8404`.
- **`stats uri`**: Sets the URI for the dashboard (e.g., `/stats`).
- **`stats refresh`**: Refreshes the stats page every 10 seconds.

Access the dashboard by navigating to `http://<your-server-ip>:8404/stats`.

---

#### 🛡️ **Advanced Features**
1. **Multiple Backends with Rules**:
   Use rules to route traffic to different backends based on conditions:
   ```haproxy
   frontend my_frontend
       bind 127.0.0.1:81, 127.0.0.1:82, 127.0.0.1:83
       use_backend first if { dst_port = 81 }
       use_backend second if { dst_port = 82 }
       default_backend third

   backend first
       server server1 127.0.0.1:8001

   backend second
       server server2 127.0.0.1:8002

   backend third
       server server3 127.0.0.1:8003
   ```
   - Routes traffic to different backends based on the destination port.

2. **SSL/TLS Termination**:
   Terminate SSL/TLS connections at HAProxy:
   ```haproxy
   frontend https_frontend
       bind *:443 ssl crt /etc/haproxy/certs/mycert.pem
       default_backend https_backend

   backend https_backend
       server web1 192.168.1.10:80
   ```
   - **`ssl crt`**: Specifies the SSL certificate for HTTPS.

---

#### 🚀 **Testing Your Configuration**
1. **Check Configuration**:
   Before restarting HAProxy, validate your configuration:
   ```bash
   sudo haproxy -c -f /etc/haproxy/haproxy.cfg
   ```
   If there are no errors, restart HAProxy:
   ```bash
   sudo systemctl restart haproxy
   ```

2. **Test Load Balancing**:
   Use `curl` to test:
   ```bash
   curl http://<your-server-ip>
   ```

---

#### 🎯 **Conclusion**
HAProxy is a versatile and reliable solution for **load balancing** and **proxying**. By configuring its `global`, `defaults`, `frontend`, and `backend` sections, you can optimize your server environment for **high availability** and **performance**. With features like **monitoring**, **SSL termination**, and **custom rules**, HAProxy is a must-have tool for modern infrastructure.

Happy load balancing! 🎉

---

## **Author** ✍️

Created by [Ali Rahmati](https://github.com/alirahmti). If you find this repository helpful, feel free to fork it or contribute!
