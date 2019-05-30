#!/bin/bash

if [ $UID -ne 0 ]; then
        echo "请使用root运行 !!!"
        exit 1
fi

SHELL_DIR='/etc/opt/shell'
[[ -d "${SHELL_DIR}" ]] || mkdir ${SHELL_DIR}

wget -t 3 -w 5 -T 10 -nv -O ${SHELL_DIR}/rm_with_prompt.sh http://183.136.203.103:889/app_install/config/rm_with_prompt.sh
chmod +x ${SHELL_DIR}/rm_with_prompt.sh

#echo "alias rm='/etc/opt/shell/rm_with_prompt.sh'" > /etc/profile.d/zz_rm_with_prompt.sh
[[ -f "/etc/profile.d/zz_rm_with_prompt.sh" ]] && rm /etc/profile.d/zz_rm_with_prompt.sh

grep -q "alias rm='/etc/opt/shell/rm_with_prompt.sh'" /etc/bashrc || echo -e "alias rm='/etc/opt/shell/rm_with_prompt.sh'" >> /etc/bashrc