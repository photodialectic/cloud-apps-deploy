# cloud-apps-deploy

Terraform deployment for the [cloud-apps](../cloud-apps) Docker Compose stack
(Traefik + self-hosted apps behind a wildcard domain). Multi-provider by
design; **DigitalOcean** is the first supported provider.

## Layout

```
cloud-apps-deploy/
  main.tf                  # selects the provider module via var.cloud_provider
  variables.tf             # provider-agnostic inputs (env_file, repo)
  variables_do.tf          # DigitalOcean-specific knobs
  outputs.tf
  providers.tf
  terraform.tfvars.example
  modules/
    digitalocean/          # droplet + firewall + DNS + cloud-init bootstrap
      main.tf
      variables.tf
      outputs.tf
      cloud-init.yaml.tpl
```

Adding a new provider = drop a `modules/<provider>/` exposing the same
inputs/outputs and reference it from `main.tf` with a `count` guard.

## What it provisions (DigitalOcean)

- A Droplet running Docker, bootstrapped via cloud-init:
  - installs `git`
  - clones `cloud_apps_repo_url` @ `cloud_apps_repo_ref` to `/opt/cloud-apps`
  - writes `/opt/cloud-apps/.env` verbatim from your local `env_file` (e.g.
    `../cloud-apps/.env`)
  - runs `docker compose up -d`
- A firewall allowing 22 (configurable source), 80, 443, and ICMP
- DNS records on a DigitalOcean-managed domain:
  - `*.<dns_domain>` → droplet IPv4 (wildcard, supports any app you add to compose)
  - `@.<dns_domain>` → droplet IPv4

## Prerequisites

1. **DigitalOcean account + API token** exported as `DIGITALOCEAN_TOKEN`.
2. **SSH key(s)** already uploaded to DigitalOcean (DigitalOcean → Settings →
   Security). Pass their names via `do_ssh_key_names`.
3. **A domain managed by DigitalOcean DNS**. The droplet's IPv4 is written into
   `*.<dns_domain>` and `@.<dns_domain>`. If your registrar is elsewhere,
   point its NS records at DigitalOcean first, then create the domain in DO:
   ```bash
   doctl compute domain create example.com
   ```
4. `cloud-apps` repo URL reachable from the droplet (public by default; for
   private repos, use an HTTPS-with-token or deploy-key URL).

## Quick start

First set up `cloud-apps/.env` (from `cloud-apps/.env.example`) using the CLI —
`./cloud-apps config edit` or `config set` — so `BASE_DOMAIN`, `ACME_EMAIL`,
`TRAEFIK_DASHBOARD_USER`/`_PASSWORD_HASH`, and `CLOUD_APP_USER`/`_PASSWORD_HASH`
are all correct locally; that file is what gets shipped to the droplet.

```bash
cd cloud-apps-deploy
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: env_file (defaults to ../cloud-apps/.env),
# do_dns_domain, do_ssh_key_names
export DIGITALOCEAN_TOKEN=dop_xxx

terraform init
terraform plan
terraform apply
```

Outputs include the droplet IPv4, the DNS records created, and `base_domain`
(parsed out of `env_file`, not set separately in tfvars). Terraform doesn't
track which apps are running — it's whatever `cloud-apps/docker-compose.yml`
defines at the time, and each app is served at `https://<app>.<base_domain>`.
See "Managing apps after bootstrap" below.

## Managing apps after bootstrap

Terraform only provisions the droplet, firewall, and DNS once; it does not
track which apps are running. The intended flow is:

1. `terraform apply` to stand up the server (cloud-init clones `cloud-apps`,
   copies your `.env`, and runs `docker compose up -d` once).
2. SSH in (`ssh root@<server_ipv4>`) and use the CLI from
   `cloud_apps_install_path` (default `/opt/cloud-apps`) to add/remove apps
   and edit config directly on the server:
   ```bash
   cd /opt/cloud-apps
   ./cloud-apps apps add <name>
   ./cloud-apps apps remove <name>
   ./cloud-apps config edit
   docker compose up -d --remove-orphans   # after any change
   ```
3. The wildcard DNS record (`*.<dns_domain>`) already routes any new
   `<app>.<base_domain>` hostname to the droplet, so new apps just need a
   matching `Host()` rule in `docker-compose.yml` — no terraform or DNS
   changes required.

Re-running `terraform apply` later will not revert manual on-server changes
(it only touches the droplet/firewall/DNS resources and the *initial*
cloud-init payload, which doesn't re-run after first boot).

## Password hashes

`cloud-apps` stores basic-auth hashes in `.env` — `TRAEFIK_DASHBOARD_PASSWORD_HASH`
for the Traefik dashboard and a shared `CLOUD_APP_PASSWORD_HASH` for every
other app (FreeCAD, OrcaSlicer, ...) behind basic-auth. Manage both with the
CLI (`./cloud-apps config edit`, or `./cloud-apps config set <KEY> <password>`),
which bcrypt-hashes and `$`-doubles automatically — you no longer need to run
`htpasswd` or hand-escape `$` yourself, and terraform never sees plaintext.

## DNS note

The module expects the domain to already exist in your DigitalOcean account
(it uses a `data "digitalocean_domain"` lookup). Creating the zone is
intentionally out of scope so a destroy doesn't delete your domain.

`base_domain` must be equal to or a subdomain of `do_dns_domain`. For a
subdomain setup like `cloud-apps.example.com` on a root zone `example.com`,
add the matching subdomain zone in DO first (or extend the module to create
it).

## Notes / limitations

- cloud-init only runs on first boot. To push `.env` changes after the droplet
  exists, `terraform taint digitalocean_droplet.this` (recreates the droplet)
  or just `scp cloud-apps/.env root@<ip>:/opt/cloud-apps/.env && ssh root@<ip>
  "cd /opt/cloud-apps && docker compose up -d"`.
- Traefik's ACME state and app config live in the cloned repo's
  `./letsencrypt` and `./config` directories on the droplet's disk — they are
  not managed by Terraform and will be lost if the droplet is destroyed.
  Consider attaching a volume or snapshotting before `destroy`.
- `do_firewall_ssh_source_ranges` defaults to the open internet. Restrict it.
