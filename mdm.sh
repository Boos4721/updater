#!/bin/bash
set -euo pipefail

# ============================================================
# MDM 绕过脚本 - 修复版
# 必须在 macOS 恢复模式 (Recovery) + SIP 禁用后运行
# ============================================================

# ----- 路径配置 -----
VOLUME="/Volumes/Macintosh HD"
VOLUME_DATA="${VOLUME} - Data"
DSCL_DB="${VOLUME_DATA}/private/var/db/dslocal/nodes/Default"
HOSTS_FILE="${VOLUME}/etc/hosts"

# ----- 预检函数 -----
check_prerequisites() {
    if [[ $(id -u) -ne 0 ]]; then
        echo "错误：必须以 root 身份运行（恢复模式终端默认是 root）"
        exit 1
    fi

    if [[ ! -d "$VOLUME" ]]; then
        echo "错误：未找到系统卷 $VOLUME"
        echo "请先运行 'diskutil list' 确认卷名，并修改脚本中的 VOLUME 变量"
        exit 1
    fi

    if [[ ! -d "$VOLUME_DATA" ]]; then
        echo "错误：未找到 Data 卷 $VOLUME_DATA"
        exit 1
    fi

    if csrutil status 2>/dev/null | grep -q "enabled"; then
        echo "警告：SIP 似乎仍处于启用状态"
        echo "请先运行 'csrutil disable'，然后重启进入恢复模式再次执行"
        read -rp "仍要继续吗？(y/N): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    fi
}

# ----- Hosts 去重追加 -----
add_host_block() {
    local host="$1"
    if grep -qF "$host" "$HOSTS_FILE" 2>/dev/null; then
        echo "  Hosts 中已存在 $host，跳过"
    else
        echo "0.0.0.0 $host" >> "$HOSTS_FILE"
        echo "  已屏蔽 $host"
    fi
}

# ----- 重置 MDM 标记文件 -----
clear_cloud_config() {
    local config_dir=""
    for candidate in \
        "${VOLUME}/var/db/ConfigurationProfiles/Settings" \
        "${VOLUME_DATA}/var/db/ConfigurationProfiles/Settings"
    do
        if [[ -d "$candidate" ]]; then
            config_dir="$candidate"
            break
        fi
    done

    if [[ -z "$config_dir" ]]; then
        echo "警告：未找到 ConfigurationProfiles/Settings，尝试创建..."
        mkdir -p "${VOLUME}/var/db/ConfigurationProfiles/Settings"
        config_dir="${VOLUME}/var/db/ConfigurationProfiles/Settings"
    fi

    for flag in \
        ".cloudConfigHasActivationRecord" \
        ".cloudConfigRecordFound" \
        ".cloudConfigProfileInstalled" \
        ".cloudConfigRecordNotFound"
    do
        : > "${config_dir}/${flag}"
        echo "  已清空 ${flag}"
    done
}

# ----- MDM 绕过主流程 -----
bypass_mdm() {
    echo "===== 绕过 Apple 设备监管 (ADM/DEP) ====="
    echo ""

    # 1. 读取用户名/显示名
    read -rp "RealName (回车默认: User): " realName
    realName="${realName:-User}"

    read -rp "用户名 (回车默认: user): " username
    username="${username:-user}"

    # 2. 强制安全密码
    while true; do
        read -rsp "设置密码 (至少 8 位): " passw
        echo
        if [[ ${#passw} -lt 8 ]]; then
            echo "密码太短，请至少输入 8 位字符。"
            continue
        fi
        read -rsp "再次确认密码: " passw2
        echo
        if [[ "$passw" != "$passw2" ]]; then
            echo "两次输入不一致，请重新设置。"
        else
            break
        fi
    done

    # 3. 获取可用 UID（优先 501，若被占用则取最大+1）
    local uid_target=501
    local existing_uids
    existing_uids=$(dscl -f "$DSCL_DB" localhost -list "/Local/Default/Users" UniqueID 2>/dev/null | awk '{print $2}' | sort -n | tail -1 || true)
    if [[ -n "$existing_uids" && "$existing_uids" -ge 501 ]]; then
        if dscl -f "$DSCL_DB" localhost -read "/Local/Default/Users/${username}" 2>/dev/null | grep -q "RecordName:"; then
            echo "用户 '$username' 已存在，跳过创建。"
        else
            uid_target=$((existing_uids + 1))
            echo "警告：UID 501 已被占用，将使用 UID $uid_target"
        fi
    fi

    # 4. 创建用户（修复：补全头像属性）
    echo "正在创建用户 '$username' (UID $uid_target) ..."

    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" RealName "$realName"
    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" UniqueID "$uid_target"
    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
    dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" hint ""

    # 修复：写入默认头像路径，避免锁屏无法显示头像
    if [[ -f "/System/Library/Templates/Data/Library/User Pictures/Fun/Yin-Yang.heic" ]]; then
        dscl -f "$DSCL_DB" localhost -create "/Local/Default/Users/$username" picture "/Library/User Pictures/Fun/Yin-Yang.heic"
    fi

    # 创建家目录
    mkdir -p "${VOLUME_DATA}/Users/${username}"
    dscl -f "$DSCL_DB" localhost -passwd "/Local/Default/Users/$username" "$passw"
    dscl -f "$DSCL_DB" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"

    # 5. 屏蔽 MDM 域名（修复：移除 albert/gdmf，避免证书和更新异常）
    echo "正在更新 hosts 文件..."
    for host in \
        deviceenrollment.apple.com \
        mdmenrollment.apple.com \
        iprofiles.apple.com \
        vpp.itunes.apple.com \
        ppq.apple.com \
        acmdm.apple.com; do
        add_host_block "$host"
    done

    # 6. 清空云配置记录
    echo "正在清除 MDM 配置标记..."
    clear_cloud_config

    # 7. 伪造设置完成
    touch "${VOLUME_DATA}/private/var/db/.AppleSetupDone"
    echo "已跳过开机设置向导"

    echo ""
    echo "===== 完成 ====="
    echo "用户: $username"
    echo "UID:  $uid_target"
    echo ""
    echo "建议：重启后如果仍需屏蔽剩余通知，请重新进入恢复模式运行本脚本的 [禁用通知] 选项"
}

# ----- 禁用通知 -----
disable_notifications() {
    echo "正在禁用 MDM 通知..."
    clear_cloud_config
    echo "完成"
}

# ----- 状态查询 -----
show_status() {
    echo "----- MDM 状态 -----"
    profiles show -type enrollment 2>/dev/null || echo "无法获取（可能不在正常系统环境）"
    echo ""
    echo "----- SIP 状态 -----"
    csrutil status 2>/dev/null || echo "无法获取 SIP 状态"
    echo ""
    echo "----- 已屏蔽域名 (hosts) -----"
    grep -E "deviceenrollment|mdmenrollment|iprofiles|vpp\.itunes|ppq|albert|gdmf|acmdm" "$HOSTS_FILE" 2>/dev/null || echo "无相关屏蔽记录"
}

# ----- 主菜单 -----
main_menu() {
    while true; do
        echo ""
        echo "=== macOS MDM 工具（修复版）==="
        echo "1) 绕过监管（创建用户+屏蔽MDM）"
        echo "2) 启用 SIP"
        echo "3) 禁用 SIP"
        echo "4) 禁用通知"
        echo "5) MDM/SIP 状态"
        echo "6) 退出"
        read -rp "请选择 [1-6]: " choice

        case "$choice" in
            1)
                bypass_mdm
                ;;
            2)
                csrutil enable
                echo "SIP 已启用，重启后生效"
                ;;
            3)
                csrutil disable
                echo "SIP 已禁用，重启后生效"
                ;;
            4)
                disable_notifications
                ;;
            5)
                show_status
                ;;
            6)
                echo "退出"
                break
                ;;
            *)
                echo "无效选项"
                ;;
        esac
    done
}

# ----- 入口 -----
check_prerequisites
main_menu
