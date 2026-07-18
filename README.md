# cloud-apps-deploy

Terraform deployment for the [cloud-apps](../cloud-apps) Docker Compose stack
(Traefik + self-hosted apps behind a wildcard domain). Multi-provider by
design; **DigitalOcean** is the first supported provider.

## Layout

```
cloud-apps-deploy/
  main.tf                  # selects the provider module via var.cloud_provider
  variables.tf             # provider-agnostic inputs (base_domain, secrets, repo)
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
  - writes `/opt/cloud-apps/.env` from your TF variables
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

```bash
cd cloud-apps-deploy
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: base_domain, acme_email, do_dns_domain,
# do_ssh_key_names, password hashes
export DIGITALOCEAN_TOKEN=dop_xxx

terraform init
terraform plan
terraform apply
```

Outputs include the droplet IPv4, the DNS records created, and the predicted
app URLs (`https://freecad.<base_domain>`, `https://traefik.<base_domain>`).

## Password hashes

`cloud-apps` stores Traefik basic-auth hashes in `.env`. The values are
interpolated into compose labels, where `$` triggers compose variable
substitution — so hashes must be `$`-doubled. Generate them with:

```bash
htpasswd -nbB admin yourpassword | sed 's/\$/\$\$/g'
```

(For FreeCAD, use `htpasswd -nb` without `-B` if you hit APR1 requirements;
match whatever `cloud-apps` expects.)

## DNS note

The module expects the domain to already exist in your DigitalOcean account
(it uses a `data "digitalocean_domain"` lookup). Creating the zone is
intentionally out of scope so a destroy doesn't delete your domain.

`base_domain` must be equal to or a subdomain of `do_dns_domain`. For a
subdomain setup like `cloud-apps.example.com` on a root zone `example.com`,
add the matching subdomain zone in DO first (or extend the module to create
it).

## Notes / limitations

- cloud-init only runs on first boot. To re-render `.env` after changing
  secrets, `terraform taint digitalocean_droplet.this` (recreates the droplet)
  or SSH in and rewrite `/opt/cloud-apps/.env` then `docker compose up -d`.
- Traefik's ACME state and app config live in the cloned repo's
  `./letsencrypt` and `./config` directories on the droplet's disk — they are
  not managed by Terraform and will be lost if the droplet is destroyed.
  Consider attaching a volume or snapshotting before `destroy`.
- `do_firewall_ssh_source_ranges` defaults to the open internet. Restrict it.
