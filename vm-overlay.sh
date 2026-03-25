#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# VM OVERLAY MANAGER v1.0.3
# Auteur : Lord Zatchi
# GitHub : https://github.com/LordZatchi/vm-overlay-manager
# ============================================================

VERSION="1.0.3"

# --- Définition des Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

export HOME="${HOME:-/root}"
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
CONF_DIR="/etc/vm-overlay"
HOOK_FILE="/etc/libvirt/hooks/qemu"
LOG_FILE="/var/log/vm-overlay.log"
RAW_URL="https://raw.githubusercontent.com/LordZatchi/vm-overlay-manager/main/vm-overlay.sh"

# --- Initialisation Système ---
sudo mkdir -p "$CONF_DIR"
sudo mkdir -p "/etc/libvirt/hooks"
sudo touch "$LOG_FILE"
sudo chmod 666 "$LOG_FILE"

# --- Fonctions de Mise à jour ---
auto_update() {
    # On récupère uniquement le numéro de version propre
    local remote_v
    remote_v=$(curl --connect-timeout 2 -s "$RAW_URL" | grep -m1 "^VERSION=" | cut -d'"' -f2 | xargs || echo "$VERSION")

    # Comparaison stricte : si remote est différent de local ET non vide
    if [[ "$remote_v" != "$VERSION" && -n "$remote_v" ]]; then
        # On vérifie si la version distante est plus récente (tri naturel)
        if [[ $(echo -e "$VERSION\n$remote_v" | sort -V | tail -n1) == "$remote_v" ]]; then
            echo -e "${MAGENTA}${BOLD}✨ MISE À JOUR DISPONIBLE (v$remote_v)${NC}"
            echo -e "${CYAN}La version actuelle est la v$VERSION.${NC}"
            echo -n -e "👉 Voulez-vous mettre à jour et redémarrer le script ? (o/N) : "
            read -r update_now
            if [[ "${update_now,,}" == "o" ]]; then
                echo -e "${BLUE}⏳ Téléchargement de la nouvelle version...${NC}"
                if curl -s "$RAW_URL" -o "$SCRIPT_PATH.tmp"; then
                    mv "$SCRIPT_PATH.tmp" "$SCRIPT_PATH"
                    chmod +x "$SCRIPT_PATH"
                    echo -e "${GREEN}✅ Mise à jour réussie ! Redémarrage...${NC}"
                    sleep 1
                    exec "$SCRIPT_PATH" "$@"
                else
                    echo -e "${RED}❌ Erreur lors du téléchargement.${NC}"
                    rm -f "$SCRIPT_PATH.tmp"
                    sleep 2
                fi
            fi
        fi
    fi
}

# --- Helpers ---
log_msg() {
  local msg="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | sudo tee -a "$LOG_FILE" >/dev/null 2>&1 || true
}

detect_vm_uri() {
  local vm_name="${1:-}"
  local uri
  for uri in qemu:///system qemu:///session; do
    if virsh -c "$uri" dominfo "$vm_name" >/dev/null 2>&1; then
      echo "$uri"
      return 0
    fi
  done
  return 1
}

virsh_cmd() {
  local uri="${LIBVIRT_URI:-}"
  if [[ -z "$uri" && -n "${VM_NAME:-}" ]]; then
    uri="$(detect_vm_uri "$VM_NAME" || true)"
  fi
  [[ -z "$uri" ]] && uri="qemu:///system"
  virsh -c "$uri" "$@"
}

list_all_vms() {
  local uri line
  for uri in qemu:///system qemu:///session; do
    while IFS= read -r line; do
      [[ -n "$line" ]] && printf '%s|%s\n' "$uri" "$line"
    done < <(virsh -c "$uri" list --all --name 2>/dev/null | grep -v '^$' || true)
  done
}

vm_state() {
  virsh_cmd domstate "$VM_NAME" 2>/dev/null || echo "offline"
  return 0
}
get_root_target() {
  virsh_cmd domblklist "$VM_NAME" --details 2>/dev/null | awk '$1=="file" && $2=="disk" && $3!="" {print $3; exit}' || true
  return 0
}
get_current_root_path() {
  local tgt
  tgt="$(get_root_target || true)"
  if [[ -z "$tgt" ]]; then
    return 0
  fi
  virsh_cmd domblklist "$VM_NAME" --details 2>/dev/null | awk -v t="$tgt" '$3==t {print $4; exit}' || true
  return 0
}

# --- Gestion Multi-VM ---
select_vm_context() {
  local configs=("$CONF_DIR"/*.conf)
  if [[ ! -e "${configs[0]}" ]]; then
    echo -e "${YELLOW}Aucune VM configurée.${NC}"
    install_wizard
    return
  fi

  echo -e "${BOLD}Sélectionnez la VM à gérer :${NC}"
  local i=1
  local vm_list=()
  for conf in "${configs[@]}"; do
    local name
    name=$(basename "$conf" .conf)
    vm_list+=("$name")
    echo -e "  $i) $name"
    ((i++))
  done
  echo -e "  a) Ajouter une nouvelle VM"
  echo -e "  r) Supprimer une VM"
  
  echo -n -e "\n👉 Choix [1] : "
  read -r choice
  choice="${choice:-1}"

  if [[ "$choice" == "a" ]]; then
    install_wizard
  elif [[ "$choice" == "r" ]]; then
    remove_vm_wizard
  elif [[ "$choice" =~ ^[0-9]+$ ]] && ((choice > 0 && choice < i)); then
    source "$CONF_DIR/${vm_list[$((choice-1))]}.conf"
    if [[ -z "${LIBVIRT_URI:-}" ]]; then
      LIBVIRT_URI="$(detect_vm_uri "$VM_NAME" || true)"
      [[ -z "${LIBVIRT_URI:-}" ]] && LIBVIRT_URI="qemu:///system"
    fi
  else
    echo -e "${RED}Choix invalide.${NC}"
    exit 1
  fi
}

remove_vm_wizard() {
  echo -e "\n${RED}Supprimer une configuration de VM :${NC}"
  local configs=("$CONF_DIR"/*.conf)
  local i=1
  for conf in "${configs[@]}"; do
    echo -e "  $i) $(basename "$conf" .conf)"
    ((i++))
  done
  read -p "Numéro à supprimer : " num
  if [[ "$num" =~ ^[0-9]+$ ]] && ((num > 0 && num < i)); then
    local to_del="${configs[$((num-1))]}"
    sudo rm -f "$to_del"
    echo -e "${GREEN}Configuration supprimée.${NC}"
    sleep 1
    select_vm_context
  fi
}

# --- Coeur du Script ---
switch_overlay() {
  local full_path="$1" manual_no_start="${2:-}"
  local state
  state=$(vm_state)
  
  if [[ "$state" == "running" || "$state" == "paused" ]]; then
      echo -e "\n${YELLOW}⚠️ La VM '$VM_NAME' est active.${NC}"
      echo -n "Arrêter la VM pour switcher ? (o/N) : "
      read -r confirm
      if [[ "${confirm,,}" == "o" ]]; then
          echo -n "⏳ Arrêt en cours..."
          virsh_cmd shutdown "$VM_NAME" >/dev/null 2>&1
          while [[ "$(vm_state)" != "shut off" ]]; do sleep 1; echo -n "."; done
          echo -e " ${GREEN}OK.${NC}"
      else return 1; fi
  fi

  local target
  target=$(get_root_target)
  if [[ -z "$target" ]]; then
  echo -e "${RED}❌ Impossible de détecter la cible disque principale de la VM ($VM_NAME).${NC}"
  echo -e "${YELLOW}Vérifie la sortie de : virsh -c ${LIBVIRT_URI:-qemu:///system} domblklist \"$VM_NAME\" --details${NC}"
  sleep 2
  return 1
  fi
  virsh_cmd detach-disk "$VM_NAME" "$target" --persistent >/dev/null 2>&1 || true
  virsh_cmd attach-disk "$VM_NAME" "$full_path" "$target" --persistent --subdriver qcow2 --targetbus virtio >/dev/null
  
  log_msg "VM $VM_NAME switched to $(basename "$full_path")"
  
  if [[ "$manual_no_start" != "--no-start" ]]; then
      if [[ "${AUTO_START:-0}" == "1" ]]; then 
          virsh_cmd start "$VM_NAME" >/dev/null 2>&1
      else
          echo -n -e "\n▶️ Démarrer la VM maintenant ? (o/N) : "
          read -r sn
          [[ "${sn,,}" == "o" ]] && virsh_cmd start "$VM_NAME" >/dev/null 2>&1
      fi
  fi
}

install_wizard() {
  clear
  echo -e "${BOLD}=== Assistant d'ajout de VM (Lord Zatchi) ===${NC}"
  
  local vm_entries=()
  local vm_names=()
  local vm_uris=()
  local line uri name

  while IFS= read -r line; do
    vm_entries+=("$line")
  done < <(list_all_vms)

  if [[ ${#vm_entries[@]} -eq 0 ]]; then
    echo -e "${RED}❌ Aucune VM détectée via libvirt (system/session).${NC}"
    exit 1
  fi

  for i in "${!vm_entries[@]}"; do
    uri="${vm_entries[$i]%%|*}"
    name="${vm_entries[$i]#*|}"
    vm_uris+=("$uri")
    vm_names+=("$name")
    echo -e "  $((i+1))) ${name} ${CYAN}[${uri}]${NC}"
  done

  echo -n "Choisir la VM [1] : "
  read -r v
  v="${v:-1}"
  VM_NAME="${vm_names[$((v-1))]}"
  LIBVIRT_URI="${vm_uris[$((v-1))]}"

  BASE_IMAGE="$(virsh_cmd domblklist "$VM_NAME" --details 2>/dev/null | awk '$1=="file" && $2=="disk"{print $4; exit}' || true)"

  if [[ -z "$BASE_IMAGE" ]]; then
    echo -e "${YELLOW}⚠ Impossible de détecter automatiquement le disque principal.${NC}"
    echo -e "${CYAN}Recherche manuelle des fichiers .qcow2 / .img...${NC}"

    local bases=()
    while IFS= read -r line; do
      bases+=("$line")
    done < <(sudo find / -type f \( -name "*.qcow2" -o -name "*.img" \) \
      -not -path "/proc/*" \
      -not -path "/sys/*" \
      -not -path "/dev/*" \
      -not -path "/run/*" \
      -not -path "/tmp/*" \
      -not -path "*/overlays/*" 2>/dev/null)

    if [[ ${#bases[@]} -eq 0 ]]; then
      echo -e "${RED}❌ Aucun disque qcow2/img trouvé sur le système.${NC}"
      exit 1
    fi

    for i in "${!bases[@]}"; do
      echo -e "  $((i+1))) ${bases[$i]}"
    done

    echo -n "Base Image [1] : "
    read -r b
    b="${b:-1}"
    BASE_IMAGE="${bases[$((b-1))]}"
  else
    echo -e "Base détectée automatiquement : ${BLUE}$BASE_IMAGE${NC}"
  fi

  echo -n "Dossier Overlays [/vm/overlays] : "
  read -r r
  OVERLAY_ROOT="${r:-/vm/overlays}"

  echo -n "Nom Default [prod] : "
  read -r p
  DEFAULT_OVERLAY_NAME="${p:-prod}"

  echo -n "Auto-start après switch (1/0) [0] : "
  read -r a
  AUTO_START="${a:-0}"

  local vm_dir="$OVERLAY_ROOT/$VM_NAME"
  mkdir -p "$vm_dir"
  [[ ! -f "$vm_dir/$DEFAULT_OVERLAY_NAME.qcow2" ]] && qemu-img create -f qcow2 -b "$BASE_IMAGE" -F qcow2 "$vm_dir/$DEFAULT_OVERLAY_NAME.qcow2" >/dev/null

  sudo tee "$CONF_DIR/$VM_NAME.conf" >/dev/null <<EOF
VM_NAME="$VM_NAME"
LIBVIRT_URI="$LIBVIRT_URI"
BASE_IMAGE="$BASE_IMAGE"
OVERLAY_ROOT="$OVERLAY_ROOT"
DEFAULT_OVERLAY_NAME="$DEFAULT_OVERLAY_NAME"
AUTO_START="$AUTO_START"
EOF

  # Hook installation
  sudo tee "$HOOK_FILE" >/dev/null <<EOF
#!/usr/bin/env bash
domain="\$1"; event="\$2"
if [[ "\$event" == "release" && -f "$CONF_DIR/\$domain.conf" ]]; then
  ( sleep 3; "$SCRIPT_PATH" default "\$domain" ) >/dev/null 2>&1 &
fi
exit 0
EOF
  sudo chmod +x "$HOOK_FILE" "$SCRIPT_PATH"
  sudo systemctl reload libvirtd >/dev/null 2>&1 || true
  echo -e "\n✅ VM $VM_NAME configurée avec succès."
  sleep 1
}

menu() {
  auto_update "$@"
  
  select_vm_context
  while true; do
    local vm_dir="$OVERLAY_ROOT/$VM_NAME"
    local cur
    cur=$(get_current_root_path)
    clear
    echo -e "${MAGENTA}${BOLD}=== VM OVERLAY MANAGER v$VERSION ===${NC}"
    echo -e "${BOLD}Auteur   : Lord Zatchi (https://github.com/LordZatchi/)${NC}"
    echo -e "----------------------------------------"
    echo -e "VM       : ${BLUE}$VM_NAME${NC} (État: ${YELLOW}$(vm_state)${NC})"
    echo -e "URI      : ${CYAN}${LIBVIRT_URI:-N/A}${NC}"
    echo -e "Base     : ${CYAN}$BASE_IMAGE${NC}"
    echo -e "Actif    : ${GREEN}$(basename "${cur:-N/A}")${NC}"
    echo -e "Dossier  : $vm_dir"
    echo "----------------------------------------"
    echo -e " 1) 📦 Lister & Switcher"
    echo -e " 2) ➕ Créer un overlay"
    echo -e " 3) 🔄 Retour au Default (${GREEN}${DEFAULT_OVERLAY_NAME}${NC})"
    echo -e " 4) 📜 Voir les logs"
    echo -e " 5) 🗑️  Supprimer un overlay"
    echo -e " i) ⚙️  Reconfigurer la VM actuelle"
    echo -e " v) 🔄 Changer de VM"
    echo -e " q) 🚪 Quitter"
    echo -n -e "\n👉 Action : "
    read -r choice
    case "$choice" in
      1) 
        local files=(); while IFS= read -r line; do files+=("$line"); done < <(find "$vm_dir" -maxdepth 1 -name "*.qcow2" 2>/dev/null)
        if [[ ${#files[@]} -eq 0 ]]; then echo "Aucun overlay."; sleep 1; continue; fi
        for i in "${!files[@]}"; do
            local fn
            fn=$(basename "${files[$i]}")
            local s=""
            [[ "${fn%.qcow2}" == "$DEFAULT_OVERLAY_NAME" ]] && s=" ${GREEN}[DEFAULT]${NC}"
            echo -e "  $((i+1))) $(printf "%-20s" "$fn") $s"
        done
        echo -n "Choix [1] : "; read -r sel; sel="${sel:-1}"; switch_overlay "${files[$((sel-1))]}" ;;
      2) echo -n "Nom de l'overlay : "; read -r n; [[ -n "$n" ]] && qemu-img create -f qcow2 -b "$BASE_IMAGE" -F qcow2 "$vm_dir/$n.qcow2" ;;
      3) switch_overlay "$vm_dir/$DEFAULT_OVERLAY_NAME.qcow2" ;;
      4) echo -e "\n--- LOGS ---"; tail -n 15 "$LOG_FILE"; echo -e "\n${YELLOW}Entrée pour revenir...${NC}"; read -r ;;
      5)
        local files=(); while IFS= read -r line; do files+=("$line"); done < <(find "$vm_dir" -maxdepth 1 -name "*.qcow2" 2>/dev/null)
        echo -e "\n${RED}${BOLD}--- SUPPRESSION ---${NC}"
        for i in "${!files[@]}"; do echo -e "  $((i+1))) $(basename "${files[$i]}")"; done
        echo -n "Supprimer quel numéro ? : "; read -r del_sel
        if [[ -n "$del_sel" && ${files[$((del_sel-1))]+_} ]]; then
            local to_rm="${files[$((del_sel-1))]}"
            if [[ "$to_rm" == "$cur" ]]; then
                echo -e "${RED}Erreur : Impossible de supprimer l'overlay actif !${NC}"
                sleep 2
            else
                echo -n "Confirmer la suppression de $(basename "$to_rm") ? (o/N) : "
                read -r confirm
                if [[ "${confirm,,}" == "o" ]]; then
                    rm -f "$to_rm"
                    echo -e "${GREEN}Fichier supprimé.${NC}"
                fi
                sleep 1
            fi
        fi
        ;;
      i) install_wizard ;;
      v) select_vm_context ;;
      q) exit 0 ;;
      *) echo "Invalide"; sleep 1 ;;
    esac
  done
}

# --- Entry Point ---
if [[ "${1:-}" == "default" ]]; then
  VM_NAME="${2:-}"
  if [[ -f "$CONF_DIR/$VM_NAME.conf" ]]; then
    source "$CONF_DIR/$VM_NAME.conf"
    if [[ -z "${LIBVIRT_URI:-}" ]]; then
      LIBVIRT_URI="$(detect_vm_uri "$VM_NAME" || true)"
      [[ -z "${LIBVIRT_URI:-}" ]] && LIBVIRT_URI="qemu:///system"
    fi
    switch_overlay "$OVERLAY_ROOT/$VM_NAME/$DEFAULT_OVERLAY_NAME.qcow2" "--no-start"
  fi
else
  menu "$@"
fi
