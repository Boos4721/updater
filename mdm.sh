#!/bin/bash


    system_path="/Volumes/Macintosh HD"


PS3='请输入您的选择: '
options=("绕过监管" "启用 SIP" "禁用 SIP" "禁用通知" "MDM 状态" "SIP 状态" "退出脚本")
select opt in "${options[@]}"; do
    case $opt in
        "绕过监管")
            read -rp "RealName (默认: Boos): " realName
            realName=${realName:-Boos}
            read -rp "用户名 (默认: Boos): " username
            username=${username:-Boos}
            read -rsp "密码 (默认: boos): " passw
            passw=${passw:-boos}
            echo
            dscl_path="$system_path - Data/private/var/db/dslocal/nodes/Default"
            echo "创建用户中，请稍等..."
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
            mkdir -p "$system_path - Data/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
            dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
            dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
            for host in \
                deviceenrollment.apple.com \
                mdmenrollment.apple.com \
                iprofiles.apple.com \
                vpp.itunes.apple.com \
                ppq.apple.com \
                albert.apple.com \
                gdmf.apple.com \
                acmdm.apple.com; do
                echo "0.0.0.0 $host" >> "$system_path/etc/hosts"
            done
            for file in \
                "$system_path/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord" \
                "$system_path/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" \
                "$system_path/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled" \
                "$system_path/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"; do
                : > "$file"
            done
            touch "$system_path - Data/private/var/db/.AppleSetupDone"
            echo "屏蔽完成"
            break
            ;;
        "启用 SIP")
            csrutil enable
            break
            ;;
        "禁用 SIP")
            csrutil disable
            break
            ;;
        "禁用通知")
            # 检测配置文件的正确位置（恢复模式下路径不同）
            config_base=""
            for candidate in \
                "$system_path/var/db/ConfigurationProfiles/Settings" \
                "/var/db/ConfigurationProfiles/Settings"; do
                if [ -d "$candidate" ]; then
                    config_base="$candidate"
                    break
                fi
            done
            if [ -n "$config_base" ]; then
                for file in "$config_base/.cloudConfigHasActivationRecord" \
                            "$config_base/.cloudConfigRecordFound" \
                            "$config_base/.cloudConfigProfileInstalled" \
                            "$config_base/.cloudConfigRecordNotFound"; do
                    [ -f "$file" ] && : > "$file"
                done
                echo "通知已禁用"
            else
                echo "未找到 ConfigurationProfiles 目录"
            fi
            ;;
        "MDM 状态")
            profiles show -type enrollment
            break
            ;;
        "SIP 状态")
            csrutil status
            break
            ;;
        "退出脚本")
            break
            ;;
        *)
            echo "无效选项 $REPLY"
            ;;
    esac
done
