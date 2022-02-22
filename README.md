# Squid Proxy with SSL bump

## What is bump ssl ?

```
[Client] ----> [Squid] ----> [Website]

            Squid is rewriting
            Cert from Given CA
[Client] <---- [Squid] <---- [Website]
```

## How to enable this feature ?

```bash
# Create parameters file for Diffie-Hellman algorithm
openssl dhparam -outform PEM -out squid-dhparam.pem 2048
# Generate squid root ca
openssl req -new -newkey rsa:2048 -sha256 -days 365 -nodes -x509 -extensions v3_ca -keyout squid-ca.key -out squid-ca.crt
# You can install it has a trusted root ca
sudo mv squid-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

```bash
# And then run squid proxy with bump ssl enabled
docker run \
  -it \
  -e BUMP_SSL_ENABLED="true" \
  -e AUTH_USERNAME="my-user" \
  -e AUTH_PASSWORD="aVeryStrongPassword" \
  -v $(pwd)/squid-public.crt:/etc/squid/bump.crt:ro \
  -v $(pwd)/squid-private.key:/etc/squid/bump.key:ro \
  -v $(pwd)/squid-dhparam.pem:/etc/squid/bump_dhparam.pem:ro \
  -p 3128:3128 \
  skyloud/squid:5.4.1
```

## How to use proxy without ssl bump

```bash
# Run squid with only basic auth
docker run \
  -it \
  -e AUTH_USERNAME="my-user" \
  -e AUTH_PASSWORD="aVeryStrongPassword" \
  -e ALLOWED_DOMAINS="www.google.com" \
  -p 3128:3128 \
  skyloud/squid:5.4.1
```

## List of environment variables

| Name               | Default                     | Description                                                       |
| ------------------ | --------------------------- | ----------------------------------------------------------------- |
| `ALLOWED_DOMAINS`  | `".skyloud.app"`            | White-spaced list of domains allowed to be fetched through proxy. |
| `AUTH_USERNAME`    | `""`                        | Username for authentication. Leave blank to disable feature.      |
| `AUTH_PASSWORD`    | `""`                        | Password for authentication.                                      |
| `AUTH_REALM`       | `"Authentication required"` | Message from proxy when auth is required                          |
| `BUMP_SSL_ENABLED` | `"false"`                   | Bump ssl domain certs with given CA when enabled                  |
