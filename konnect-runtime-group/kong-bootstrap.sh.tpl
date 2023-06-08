#!/bin/bash
export RUNTIME_GROUP_NAME=${ runtime_group_name }
export KONG_VERSION=${ kong_version }
export INSTALL_KONG_FROM_S3_PATH=${ install_kong_from_s3_path }

echo '> IN: cloud-init script'

# Refresh package manager
apt update

# Prereq
apt install -y zip unzip ca-certificates jq

# Install AWS CLI
echo '>> Installing AWS CLI'
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

if ! [ -z "$INSTALL_KONG_FROM_S3_PATH" ];
then
  echo '>> Copying Kong debs from S3'

  aws s3 cp $INSTALL_KONG_FROM_S3_PATH /tmp/kong.deb
  apt install -y /tmp/kong.deb
  rm -f /tmp/kong.deb
else
  # Install Kong from deb repository
  echo '>> Installing Kong from deb repository online'
  echo "deb [trusted=yes] https://download.konghq.com/gateway-3.x-ubuntu-$(lsb_release -sc)/ default all" | tee /etc/apt/sources.list.d/kong.list
  apt update
  apt install -y kong-enterprise-edition=$KONG_VERSION
  apt-mark hold kong-enterprise-edition
fi

echo ">> Trying to read Konnect clustering information from secretsmanager://konnect/rg/$RUNTIME_GROUP_NAME"
# Get runtime group information from Secrets Manager
CONTROL_PLANE_CLUSTER_HOSTNAME=$(aws secretsmanager get-secret-value --output text --secret-id "konnect/rg/$RUNTIME_GROUP_NAME" --query 'SecretString' | jq -r '.cluster_hostname')
CONTROL_PLANE_TELEMETRY_HOSTNAME=$(aws secretsmanager get-secret-value --output text --secret-id "konnect/rg/$RUNTIME_GROUP_NAME" --query 'SecretString' | jq -r '.telemetry_hostname')
aws secretsmanager get-secret-value --output text --secret-id "konnect/rg/$RUNTIME_GROUP_NAME" --query 'SecretString' | jq -r '.cert' > /etc/kong/cluster-cert.crt
aws secretsmanager get-secret-value --output text --secret-id "konnect/rg/$RUNTIME_GROUP_NAME" --query 'SecretString' | jq -r '.key' > /etc/kong/cluster-cert.key

# Generate a null certificate for ALB compatibility
openssl req -x509 -newkey rsa:4096 -keyout /etc/kong/proxy-cert.key -out /etc/kong/proxy-cert.crt -sha256 -days 3650 -nodes -subj "/C=XX/ST=StateName/L=CityName/O=CompanyName/OU=CompanySectionName/CN=CommonNameOrHostname"

cat <<EOF > /etc/kong/kong.conf
# Server
proxy_listen = 0.0.0.0:8443 ssl http2
status_listen = 0.0.0.0:8100
ssl_cert = /etc/kong/proxy-cert.crt
ssl_cert_key = /etc/kong/proxy-cert.key

# Clustering
role = data_plane
database = off
cluster_mtls = pki
cluster_control_plane = $CONTROL_PLANE_CLUSTER_HOSTNAME:443
cluster_server_name = $CONTROL_PLANE_CLUSTER_HOSTNAME
cluster_telemetry_endpoint = $CONTROL_PLANE_TELEMETRY_HOSTNAME:443
cluster_telemetry_server_name = $CONTROL_PLANE_TELEMETRY_HOSTNAME
cluster_cert = /etc/kong/cluster-cert.crt
cluster_cert_key = /etc/kong/cluster-cert.key
lua_ssl_trusted_certificate = system
konnect_mode = on
vitals = off

# Load Balancing
trusted_ips = ${ vpc_cidr }
real_ip_recursive = on
real_ip_header = x-forwarded-for

# OTel
tracing_instrumentations = all
tracing_sampling_rate = 1.0
EOF

# Replace broken SAML plugin on Ubuntu with nothing stub
rm -f /usr/local/share/lua/5.1/kong/plugins/saml/handler.ljbc
cat <<EOF > /usr/local/share/lua/5.1/kong/plugins/saml/handler.lua
local _M = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}
return _M
EOF

systemctl start kong-enterprise-edition
