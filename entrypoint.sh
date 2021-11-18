#!/bin/bash

cd /tranzact-blockchain

. ./activate

if [[ $(tranzact keys show | wc -l) -lt 5 ]]; then
    if [[ ${keys} == "generate" ]]; then
      echo "to use your own keys pass them as a text file -v /path/to/keyfile:/path/in/container and -e keys=\"/path/in/container\""
      tranzact init && tranzact keys generate
    elif [[ ${keys} == "copy" ]]; then
      if [[ -z ${ca} ]]; then
        echo "A path to a copy of the farmer peer's ssl/ca required."
        exit
      else
      tranzact init -c ${ca}
      fi
    elif [[ ${keys} == "type" ]]; then
      tranzact init
      echo "Call from docker shell: tranzact keys add"
      echo "Restart the container after mnemonic input"
    else
      tranzact init && tranzact keys add -f ${keys}
    fi
    
    sed -i 's/localhost/127.0.0.1/g' ~/.tranzact/mainnet/config/config.yaml
else
    for p in ${plots_dir//:/ }; do
        mkdir -p ${p}
        if [[ ! "$(ls -A $p)" ]]; then
            echo "Plots directory '${p}' appears to be empty, try mounting a plot directory with the docker -v command"
        fi
        tranzact plots add -d ${p}
    done

    if [[ ${farmer} == 'true' ]]; then
      tranzact start farmer-only
    elif [[ ${harvester} == 'true' ]]; then
      if [[ -z ${farmer_address} || -z ${farmer_port} || -z ${ca} ]]; then
        echo "A farmer peer address, port, and ca path are required."
        exit
      else
        tranzact configure --set-farmer-peer ${farmer_address}:${farmer_port}
        tranzact start harvester
      fi
    else
      tranzact start farmer
    fi
fi

finish () {
    echo "$(date): Shutting down tranzact"
    tranzact stop all
    exit 0
}

trap finish SIGTERM SIGINT SIGQUIT

sleep infinity &
wait $!
