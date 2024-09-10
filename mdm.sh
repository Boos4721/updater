#!/bin/bash

read -p "请输入系统路径 (默认路径为Macintosh HD): " input_path
if [[ -z "$input_path" ]]; then
    system_path="/Volumes/Macintosh HD"
else
    system_path="/Volumes/$input_path"
fi

PS3='请输入您的选择: '
options=("绕过监管" "启用 SIP" "禁用 SIP" "禁用通知" "MDM 状态" "SIP 状态" "退出脚本")
select opt in "${options[@]}"; do
    case $opt in
        "绕过监管")
            realName="Boos1"
            username="Boos1"
            passw="boos"
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
            for host in deviceenrollment.apple.com mdmenrollment.apple.com iprofiles.apple.com; do
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
            for file in \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"; do
                : > "$file"
            done
            break
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
