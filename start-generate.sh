#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

OUTPUT_FILE="/root/192-168-40-51.md"

HOSTNAME=$(hostname)
HOST_IP=$(hostname -I | awk '{print $1}')
HOST_MAC=$(ip link show | awk '/ether/ {print $2; exit}')

NODE_DESCRIPTION=$(pvesh get /nodes/"$HOSTNAME"/config 2>/dev/null | awk -F '│' '/description/ {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}')
[[ -z "$NODE_DESCRIPTION" ]] && NODE_DESCRIPTION="-"
HOST_NOTES=$(echo "$NODE_DESCRIPTION" | sed 's/%0A/\n/g; s/%3A/:/g' | sed ':a;N;$!ba;s/\n/<br>/g')

HOST_STATUS="🟢"
HOST_TYPE="Host"

cat > "$OUTPUT_FILE" <<EOF
---
tags:
  - hosts
  - PVE
ip: $HOST_IP
---

#### Proxmox Host

| name | ip | mac | notes | status | type |
| ---- | -- | --- | ----- | ------ | ---- |
| $HOSTNAME | $HOST_IP | $HOST_MAC | $HOST_NOTES | $HOST_STATUS | $HOST_TYPE |

#### Online LXC Containers and Virtual Machines

| name | ip | mac | notes | status | type |
| ---- | -- | --- | ----- | ------ | ---- |
EOF

echo "Собираем список VM онлайн..."

qm list | tail -n +2 | while read -r vmid name status _rest; do
  if [[ "$status" == "running" ]]; then
    ip="-"
    mac="-"
    notes="-"
    status_emoji="🟢"

    json=$(qm guest cmd "$vmid" network-get-interfaces 2>/dev/null)
    if [[ -n "$json" ]]; then
      ip=$(echo "$json" | jq -r '
        .[]
        | .["ip-addresses"][]? 
        | select(."ip-address-type" == "ipv4") 
        | .["ip-address"]
      ' 2>/dev/null | grep '^192\.' | head -n1 || true)

      mac=$(echo "$json" | jq -r '
        .[]
        | select(."hardware-address" != "00:00:00:00:00:00")
        | .["hardware-address"]
      ' 2>/dev/null | head -n1 || true)

      [[ -z "$ip" ]] && ip="-"
      [[ -z "$mac" ]] && mac="-"
    fi

    vm_notes=$(qm config "$vmid" 2>/dev/null | sed -n 's/^description: //p')
    [[ -z "$vm_notes" ]] && vm_notes="-"
    notes=$(echo "$vm_notes" | sed 's/%0A/\n/g; s/%3A/:/g' | sed ':a;N;$!ba;s/\n/<br>/g')

    echo "| $name | $ip | $mac | $notes | $status_emoji | VM |" >> "$OUTPUT_FILE"
  fi
done

echo "Собираем список LXC онлайн..."

pct list | tail -n +2 | while read -r lxcid status name _rest; do
  if [[ "$status" == "running" ]]; then
    ip="-"
    mac="-"
    notes="-"
    status_emoji="🟢"

    ip=$(pct exec "$lxcid" -- ip -4 -o addr show eth0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | grep '^192\.' | head -n1 || true)
    mac=$(pct exec "$lxcid" -- cat /sys/class/net/eth0/address 2>/dev/null || echo "-")
    [[ -z "$ip" ]] && ip="-"
    [[ -z "$mac" ]] && mac="-"

    lxc_notes=$(pct config "$lxcid" 2>/dev/null | sed -n 's/^description: //p')
    [[ -z "$lxc_notes" ]] && lxc_notes="-"
    notes=$(echo "$lxc_notes" | sed 's/%0A/\n/g; s/%3A/:/g' | sed ':a;N;$!ba;s/\n/<br>/g')

    echo "| $name | $ip | $mac | $notes | $status_emoji | LXC |" >> "$OUTPUT_FILE"
  fi
done

# Таблица оффлайн
echo "" >> "$OUTPUT_FILE"
echo "#### Offline LXC Containers and Virtual Machines" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"
echo "| name | ip | mac | notes | status | type |" >> "$OUTPUT_FILE"
echo "| ---- | -- | --- | ----- | ------ | ---- |" >> "$OUTPUT_FILE"

echo "Собираем список VM оффлайн..."

qm list | tail -n +2 | while read -r vmid name status _rest; do
  if [[ "$status" != "running" ]]; then
    ip="-"
    mac="-"
    notes="-"
    status_emoji="🔴"

    vm_notes=$(qm config "$vmid" 2>/dev/null | sed -n 's/^description: //p')
    [[ -z "$vm_notes" ]] && vm_notes="-"
    notes=$(echo "$vm_notes" | sed 's/%0A/\n/g; s/%3A/:/g' | sed ':a;N;$!ba;s/\n/<br>/g')

    echo "| $name | $ip | $mac | $notes | $status_emoji | VM |" >> "$OUTPUT_FILE"
  fi
done

echo "Собираем список LXC оффлайн..."

pct list | tail -n +2 | while read -r lxcid status name _rest; do
  if [[ "$status" != "running" ]]; then
    ip="-"
    mac="-"
    notes="-"
    status_emoji="🔴"

    lxc_notes=$(pct config "$lxcid" 2>/dev/null | sed -n 's/^description: //p')
    [[ -z "$lxc_notes" ]] && lxc_notes="-"
    notes=$(echo "$lxc_notes" | sed 's/%0A/\n/g; s/%3A/:/g' | sed ':a;N;$!ba;s/\n/<br>/g')

    echo "| $name | $ip | $mac | $notes | $status_emoji | LXC |" >> "$OUTPUT_FILE"
  fi
done

echo "Готово. Результат в $OUTPUT_FILE"