#!/usr/bin/env zsh

script_name="$0"
new_vm="$1"
base_vm="ghcr.io/cirruslabs/macos-ventura-base:latest"
FOO="${VARIABLE:-default}"
tart_pass="admin"
tart_ip=
tart_pid=


if [ ! -z "$2" ]; then
    base_vm="$2"
fi;

# print usage
function usage(){
    die "Usage ${script_name} <new_vmname>\n"$@
}

# exit helper
function die(){
    echo "$@"
    kill -INT $$
}

# clone vm
function tart_clone(){
    tart clone $base_vm $new_vm
    [ "$?" -eq 0 ] || die "Error cloning"

    tart set $new_vm --display 1440x900
    tart run $new_vm --dir="setup:~/src/one-offs/tart_setup:ro" &
    tart_pid=$!
}

function tart_get_ip(){
    tart_ip=`tart ip $new_vm`
}

# ssh into tart vm
function tart_ssh_setup(){
    export tart_ip=$tart_ip tart_pass=$tart_pass
    expect <<'END_EXPECT'
        spawn ssh -o StrictHostKeyChecking=no "admin@$env(tart_ip)"
        expect {
            "*?assword:" {
                send $env(tart_pass)\r
                exp_continue
            }
            "~"
        }
        set timeout -1
        send "cd '/Volumes/My Shared Files/setup/resources/' \r"
        send "sudo su \r"
        send "chmod a+x ./run.sh \r"
        send "./run.sh \r"
        set timeout 2
        send "sleep 2 && shutdown -h now &\r"
        send "exit\r"
        expect eof
END_EXPECT
}

# Wait 20 seconds before killing the pid
function wait_kill(){
    pid=$1
    threshold=20
    count=0
    while ps -p $pid > /dev/null; do
        sleep 1
        if [ "$count" -gt "$threshold" ]; then
            echo "Shutdown failed. killing manually"
            kill ${pid}
        fi
        count=$((count+1))
    done
}

function try_n_times(){

}

# Start new vm
function tart_run_ssh(){
    echo "Starting up newly provisioned VM"
    tart run $1 &
    sleep 10
    ssh admin@$tart_ip   
}

# validate
[ -z "$new_vm" ] && usage "new_vmname cannot be empty"

# main
#  Clone, customize and start the vm
#  Wait 10 seconds before running a script via expect/ssh
#  Wait for 20 seconds for it to shutdown and kill it
tart_clone
sleep 10
tart_get_ip
tart_ssh_setup
wait_kill $tart_pid

tart_run_ssh $new_vm
