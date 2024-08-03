#!/bin/bash

PS3='请输入您的选择: '
options=("绕过监管" "启用 SIP" "禁用 SIP" "禁用通知 (SIP)" "禁用通知" "MDM 状态" "SIP 状态" "退出脚本")
select opt in "${options[@]}"; do
    case $opt in
        "绕过监管")
            if [ -d "/Volumes/Macintosh HD - Data" ]; then
                diskutil rename "Macintosh HD - Data" "Data"
            fi
            realName="Boos"
            username="Boos"
            passw="boos"
            dscl_path="/Volumes/Data/private/var/db/dslocal/nodes/Default"
            echo "创建用户中，请稍等..."
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "501"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
            mkdir -p "/Volumes/Data/Users/$username"
            dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
            dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
            dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
            for host in deviceenrollment.apple.com mdmenrollment.apple.com iprofiles.apple.com; do
                echo "0.0.0.0 $host" >> "/Volumes/Macintosh HD/etc/hosts"
            done
            for file in \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"; do
                : > "$file"
            done
            touch "/Volumes/Data/private/var/db/.AppleSetupDone"
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
        "禁用通知 (SIP)")
            for file in \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled" \
                "/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"; do
                : > "$file"
            done
            break
            ;;
        "禁用通知")
            for file in \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigHasActivationRecord" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordFound" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigProfileInstalled" \
                "/Volumes/Macintosh HD/var/db/ConfigurationProfiles/Settings/.cloudConfigRecordNotFound"; do
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
