#cloud-config
package_update: true

packages:
  - git
  - apache2-utils

write_files:
  - path: /opt/cloud-apps.env.staging
    permissions: "0600"
    owner: root:root
    content: |
      ${indent(6, env_file_content)}

runcmd:
  - |
    echo "=== cloud-apps bootstrap: $(date) ==="
  - |
    set -e
    install -d -m 0755 /opt
    if [ ! -d "${install_path}/.git" ]; then
      rm -rf "${install_path}"
      git clone --depth 1 --branch "${repo_ref}" "${repo_url}" "${install_path}"
    else
      git -C "${install_path}" fetch --depth 1 origin "${repo_ref}"
      git -C "${install_path}" checkout "${repo_ref}"
      git -C "${install_path}" reset --hard origin/"${repo_ref}"
    fi
    install -m 0600 -o root -g root /opt/cloud-apps.env.staging "${install_path}/.env"
    rm -f /opt/cloud-apps.env.staging
  - |
    cd "${install_path}" && docker compose --env-file .env up -d --remove-orphans
  - |
    echo "=== cloud-apps bootstrap complete: $(date) ==="
