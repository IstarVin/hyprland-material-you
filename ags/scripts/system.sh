#!/bin/bash
# by koeqaife ;)

get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" |
        awk '{printf "%.0f\n", $2 + $4 + $6}'
}

get_ram_usage() {
    free -m | awk 'NR==2{printf "%.0f\n", $3*100/$2 }'
}

get_swap_usage() {
    free -m | awk 'NR==3 { if ($2 == 0) { print 0 } else { printf "%.0f\n", $3*100/$2 } }'
}

get_cpu_temp() {
    # sensors | grep -i 'Tctl' | awk '{sum+=$2; count+=1} END {if (count > 0) print sum/count; else print "Undefined" exit 1}' || sensors | grep -i 'core ' | awk '{sum+=$3; count+=1} END {if (count > 0) print sum/count; else print "Undefined"}'
    sensors | grep -i 'Tctl' | awk '{sum+=$2; count+=1} END {if (count > 0) print sum/count; else exit 1}' || \
    sensors | grep -i 'core ' | awk '{sum+=$3; count+=1} END {if (count > 0) print sum/count; else print "Undefined"}'
}

get_cpu_name() {
    lscpu | awk -F ': +' '/Model name/ {sub(" @ .*", "", $2); print $2}'
}

get_ram() {
    echo "$(free -m | grep Mem | awk '{print $2}') MiB"
}

get_kernel() {
    uname -r
}

get_gpu() {
    lshw -C display | grep "product" | awk -F ': ' '{print $2}' | awk '{printf "%s%s", separator, $0; separator=", "} END{print ""}'
}

get_hostname() {
    cat /etc/hostname
}

get_os() {
    hostnamectl | grep "Operating System" | awk '{for (i=3; i<=NF; i++) printf $i " "; print ""}'
}

get_uptime() {
    uptime -p | sed -e 's/up //' \
        -e 's/ hours\{0,1\}/h/g' \
        -e 's/ minutes\{0,1\}/min/g' \
        -e 's/ days\{0,1\}/d/g' \
        -e 's/ seconds\{0,1\}/sec/g' \
        -e 's/,/, /g' \
        -e 's/  */ /g' \
        -e 's/^ //g' \
        -e 's/ $//g'
}

get_usage() {
    cat <<EOF
{"cpu": $(get_cpu_usage), "ram": $(get_ram_usage), "swap": $(get_swap_usage), "cpu_temp": $(get_cpu_temp), "download": "$(get_download_speed)" , "upload": "$(get_upload_speed)"}
EOF
}

get_system_info() {
    cat <<EOF
{
    "cpu_name": "$(get_cpu_name | tr -d '\n')",
    "cpu_cores": $(nproc),
    "ram": "$(get_ram | tr -d '\n')",
    "kernel": "$(get_kernel | tr -d '\n')",
    "gpu_name": "$(get_gpu | tr -d '\n')",
    "hostname": "$(get_hostname | tr -d '\n')",
    "os": "$(get_os | tr -d '\n')",
    "uptime": "$(get_uptime | tr -d '\n')"
}
EOF
}

process_string() {
    read -r input_string
    # input_string="$1"

    # Check if the string contains 'K'
    if [[ $input_string == *K* ]]; then
        # Remove 'K' from the string
        input_string="${input_string/K/}"

        # Convert the modified string to an integer and multiply by 1000
        input_string=$((input_string * 1024))
    fi
    echo $input_string
}

get_download_speed() {
    ifstat -s $(ip route | awk '/default/ && NR==1 {print $5}') | grep $(ip route | awk '/default/ && NR==1 {print $5}') | awk '{print $6}' | process_string | numfmt --to=iec
}

get_upload_speed() {
    ifstat $(ip route | awk '/default/ && NR==1 {print $5}') | grep $(ip route | awk '/default/ && NR==1 {print $5}') | awk '{print $8}' | process_string | numfmt --to=iec
}

if [[ "$1" == "--cpu-usage" ]]; then
    get_cpu_usage
elif [[ "$1" == "--ram-usage" ]]; then
    get_ram_usage
elif [[ "$1" == "--swap-usage" ]]; then
    get_swap_usage
elif [[ "$1" == "--cpu-temp" ]]; then
    get_cpu_temp
elif [[ "$1" == "--cpu-name" ]]; then
    get_cpu_name
elif [[ "$1" == "--cpu-cores" ]]; then
    nproc
elif [[ "$1" == "--ram" ]]; then
    get_ram
elif [[ "$1" == "--kernel" ]]; then
    get_kernel
elif [[ "$1" == "--gpu-name" ]]; then
    get_gpu
elif [[ "$1" == "--hostname" ]]; then
    get_hostname
elif [[ "$1" == "--os" ]]; then
    get_os
elif [[ "$1" == "--uptime" ]]; then
    get_uptime
elif [[ "$1" == "--usage-json" ]]; then
    get_usage
elif [[ "$1" == "--json" ]]; then
    get_system_info
elif [[ "$1" == "--download" ]]; then
    get_download_speed
elif [[ "$1" == "--upload" ]]; then
    get_upload_speed
fi
