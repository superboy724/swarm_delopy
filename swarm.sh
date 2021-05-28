#!/bin/bash

#os
os=""

#const
scriptfolder=`pwd`
bee_version="0.6.1"
config_file_name="bee_config.yaml"
log_file="/var/log/bee.log"
root_dir="/usr/local/etc"
beedata_dir="/usr/local/etc/bee"
app_dir="/usr/local/bin"

#config
clef_signer_enable="false"
config="${beedata_dir}/${config_file_name}"
data_dir="${beedata_dir}/data/"
debug_api_addr="127.0.0.1:1635"
debug_api_enable="true"
password=""
swap_enable="true"
swap_endpoint="https://goerli.infura.io/v3/a2dbf3de6b9d47d79b4e2fc064432052"
swap_initial_deposit="10000000000000000"
welcome_message="hello world"

checkos(){
    if [[ $(command -v apt-get) ]];then
        os="ubuntu"
    elif [[ $(command -v yum) ]];then
        os="centos"
    else
        echo "脚本不支持本系统 退出..."
        exit
    fi

    echo "当前系统${os}"
}

installLib(){
    if [[ $os =~ "centos" ]];then
        yum install -y jq wget git
    elif [[ $os =~ "ubuntu" ]];then
        apt-get install -y jq wget git
    fi
    
}

downloadApp(){
    rm -rf swarm_temp/
    mkdir swarm_temp
    cd swarm_temp
    wget --timeout=60 https://github.com/ethersphere/bee/releases/download/v${bee_version}/bee-linux-amd64
    if [ ! -f "bee-linux-amd64" ];then
        echo "文件下载失败，请重试"
        exit
    fi
}

beforeDelopyClean(){
    rm -rf "${app_dir}/bee-linux-amd64"
    rm -rf "${beedata_dir}"
}

delopy(){
    input=""
    cp bee-linux-amd64 $app_dir
    cd $app_dir
    chmod +x bee-linux-amd64

    cd $root_dir
    mkdir $beedata_dir
    mkdir $data_dir
    cd $beedata_dir

    if [ ! -f "$config_file_name" ];then
        touch $config_file_name
        read -p "请配置客户端密码: " input
        password=${input}
        read -p "请配置swap-endpoint[默认${swap_endpoint}]: " input
        if [ ! -z "${input}" ];then
            swap_endpoint=${input}
        fi
        read -p "请配置欢迎信息[默认${welcome_message}]: " input
        if [ ! -z "${input}" ];then
            welcome_message=${input}
        fi

        echo "clef-signer-enable: ${clef_signer_enable}" >> ${config_file_name}
        echo "config: ${config}" >> ${config_file_name}
        echo "data-dir: ${data_dir}" >> ${config_file_name}
        echo "debug-api-addr: ${debug_api_addr}" >> ${config_file_name}
        echo "debug-api-enable: ${debug_api_enable}" >> ${config_file_name}
        echo "password: \"${password}\"" >> ${config_file_name}
        echo "swap-enable: ${swap_enable}" >> ${config_file_name}
        echo "swap-endpoint: ${swap_endpoint}" >> ${config_file_name}
        echo "swap-initial-deposit: \"${swap_initial_deposit}\"" >> ${config_file_name}
        echo "welcome-message: \"${welcome_message}\"" >> ${config_file_name}
        

    else
        echo "配置文件${config_file_name}已存在，跳过"
    fi
}

buildScript(){
    cd ${scriptfolder}
    touch run.sh
    echo "cd ${app_dir}" > run.sh
    echo "nohup ./bee-linux-amd64 start --config ${config} >> ${log_file} 2>&1&" >> run.sh
    echo "程序启动后，可随时按Ctrl+c退出" >> run.sh
    echo "tail -f ${log_file}" >> run.sh
    chmod +x run.sh

    touch stop.sh
    echo "#!/bin/bash" > stop.sh
    echo "processHandle=NULL" >> stop.sh
    echo "processHandle=\$(ps aux | grep bee-linux-amd64 | grep -v grep | awk 'NR==1 {print \$2}')" >> stop.sh
    echo "if [[ -z "\${processHandle}" ]];then" >> stop.sh
    echo "    echo '客户端未启动'" >> stop.sh
    echo "    exit" >> stop.sh
    echo "fi" >> stop.sh
    echo "echo 'PID:'\$processHandle" >> stop.sh
    echo "kill -9 \$processHandle" >> stop.sh
    echo "echo '关闭客户端完成'" >> stop.sh
    chmod +x stop.sh
}

clean(){
    cd ${scriptfolder}
    rm -rf swarm_temp
}


checkos
echo "-----开始安装SWARM节点客户端-----"
echo "-----当前安装版本${bee_version}-----"
if [ $USER != "root" ];then
    echo "当前不是root用户，请使用sudo或sudo su进入root用户"
    exit
fi
echo "-----STEP1:安装基本库-----"
installLib
echo "-----基本库安装完成-----"
echo "-----STEP2:下载客户端-----"
downloadApp
echo "-----客户端下载完成-----"
echo "-----STEP3:部署-----"
beforeDelopyClean
delopy
buildScript
echo "-----部署完成-----"
echo "-----清理临时文件-----"
clean
clear
echo "安装完毕"
echo "主程序所在目录:${app_dir}"
echo "配置文件所在目录:${config}"
echo "日志文件地址:${log_file}"
echo "可通过run.sh启动程序"
echo "可通过stop.sh关闭程序"