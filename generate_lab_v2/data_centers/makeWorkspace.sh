#!/bin/bash


image_mpath_definition() {
	if [ $2 = "server" ] || [ $2 = "container" ]; then
		echo "$1[image]="'"'"kathara/base"'"' >> $3
	else
		echo "$1[image]="'"'"kathara/frr"'"' >> $3
		echo "$1[sysctl]="'"'"net.ipv4.fib_multipath_hash_policy=1"'"' >> $4
	fi
}

config_file_lab() {
	tipo_macchine=$1

	echo $nome_macchina

	# Configurazione lab.conf
	for k in $(seq 0 $numero_interfacce) ; do
		
		dominio=$(./jq -r ".$tipo_macchine[$i].interfacce[$k].dominio" $file)
		macchina_dominio="$nome_macchina[$k]="'"'"$dominio"'"'
		echo $macchina_dominio >> "$nome_lab/lab.conf"
	
	done
	echo "" >> "$nome_lab/lab.conf"
}

startup_generator() {
	tipo_macchine=$1
	
	file_startup="$nome_lab/$nome_macchina.startup"
	touch $file_startup

	# Configurazione .startup
	for k in $(seq 0 $numero_interfacce) ; do
			
			ip=$(./jq -r ".$tipo_macchine[$i].interfacce[$k].ip" $file)
			cidr=$(./jq -r ".$tipo_macchine[$i].interfacce[$k].cidr" $file)
			comando="ifconfig eth"$k" $ip""/""$cidr ""up"
			echo $comando >> $file_startup
		
	done

	if [ $tipo_macchine = "container_web_server" ] || [ $tipo_macchine = "web_server" ]; then
		if [ $tipo_macchine = "container_web_server" ]; then
			echo "ip link set dev eth0 mtu 1450" >> $file_startup
		fi
		echo "" >> $file_startup
		echo "route add default gw <ip_gateway> dev <eth>" >> $file_startup
		echo "" >> $file_startup
		echo "/etc/init.d/apache2 start" >> $file_startup
	elif [ $tipo_macchine = "client" ] || [ $tipo_macchine = "load_balancer" ]; then
		echo "" >> $file_startup
		echo "route add default gw <ip_gateway> dev <eth>" >> $file_startup

		if [[ $tipo_macchine = "load_balancer" ]]; then
			echo "" >> $file_startup
			cat "$cartella_configurazioni/file_conf/load_balancer.startup" >> $file_startup
		fi
	else
		if [[ $tipo_macchine = "leaf" ]]; then
			cat "$cartella_configurazioni/file_conf/leaf.startup" >> $file_startup
		fi
		echo "" >> $file_startup
		echo "/etc/init.d/frr start" >> $file_startup
	fi

		
}
 
files_configuration_tof_spine_leaf() {

	# Creazione della directory nome_macchina/etc/frr 
	mkdir "$nome_lab/$nome_macchina"
	mkdir "$nome_lab/$nome_macchina/etc"
	mkdir "$nome_lab/$nome_macchina/etc/frr"
	
	# I template dei file di configurazione vengono copiati nella directory /etc/frr
	cp "$cartella_configurazioni/bgpd/bgpd.conf" "$nome_lab/$nome_macchina/etc/frr"
	cp "$cartella_configurazioni/bgpd/zebra.conf" "$nome_lab/$nome_macchina/etc/frr"
	cp "$cartella_configurazioni/bgpd/daemons" "$nome_lab/$nome_macchina/etc/frr"
}


files_configuration_container_web_server() {

	# Creazione della directory nome_macchina/var/www/html 
	mkdir "$nome_lab/$nome_macchina"
	mkdir "$nome_lab/$nome_macchina/var"
	mkdir "$nome_lab/$nome_macchina/var/www"
	mkdir "$nome_lab/$nome_macchina/var/www/html"
	cp "$cartella_configurazioni/index.html" "$nome_lab/$nome_macchina/var/www/html"

	# Server corrente nel file html
	sed -i "" "s/\[nome_macchina\]/$nome_macchina/g" "$nome_lab/$nome_macchina/var/www/html/index.html"
}

files_configuration_macchine() {

	# Creazione della directory nome_macchina/etc/frr
	mkdir "$nome_lab/$nome_macchina"
	mkdir "$nome_lab/$nome_macchina/etc"
	mkdir "$nome_lab/$nome_macchina/etc/frr"
	
	# I template dei file di configurazione vengono copiati nella directory /etc/frr
	cp "$cartella_configurazioni/frr/vtysh.conf" "$nome_lab/$nome_macchina/etc/frr"
	cp "$cartella_configurazioni/frr/frr.conf" "$nome_lab/$nome_macchina/etc/frr"
	cp "$cartella_configurazioni/frr/daemons" "$nome_lab/$nome_macchina/etc/frr"

	# Configurazione file /etc/frr/vtysh.conf
	sed -i "" "s/nome_host/$nome_macchina-frr/g" "$nome_lab/$nome_macchina/etc/frr/vtysh.conf"
	
	# Macchina corrente commento /etc/frr/frr.conf
	sed -i "" "s/nome_host/$nome_macchina/g" "$nome_lab/$nome_macchina/etc/frr/frr.conf"
}




# Nel file workspace.conf le interfacce inserite in ordine di eth
# File JSON di configurazione
file="workspace_data_centers.conf"

# Nome della cartella che contiene il lab
nome_lab=$(./jq -r ".nome_lab" $file)

# Versione generatore del lab
generator_version=$(./jq -r ".generator_version" $file)
echo "Workspace conf generator version: $generator_version"

# Creazione cartella lab
mkdir $nome_lab
touch "$nome_lab/lab.conf"

# File di appoggio per lab.conf
touch "$nome_lab/image.conf"
echo "# Image definitions" >> "$nome_lab/image.conf"
touch "$nome_lab/mpath_policy.conf"
echo "# Multipath policy" >> "$nome_lab/mpath_policy.conf"


# Nome cartella da cui prendere i template delle configurzioni
cartella_configurazioni=$(./jq -r ".cartella_configurazioni" $file)


# Numero di tof da configurare
n_tof=$(./jq ".tof | length" $file)
n_tof=$(( n_tof - 1 ))

# Numero di spine da configurare
n_spine=$(./jq ".spine | length" $file)
n_spine=$(( n_spine - 1 ))

# Numero di leaf da configurare
n_leaf=$(./jq ".leaf | length" $file)
n_leaf=$(( n_leaf - 1 ))

# Numero di server da configurare
n_server=$(./jq ".server | length" $file)
n_server=$(( n_server - 1 ))

# Numero di container web server da configurare
n_container=$(./jq ".container_web_server | length" $file)
n_container=$(( n_container - 1 ))

# Numero di load balancer da configurare
n_load_balancer=$(./jq ".load_balancer | length" $file)
n_load_balancer=$(( n_load_balancer - 1 ))

# Numero di macchine con protocolli da configurare
n_macchine=$(./jq ".macchine | length" $file)
n_macchine=$(( n_macchine - 1 ))

# Numero di client da configurare - solo file startup
n_client=$(./jq ".client | length" $file)
n_client=$(( n_client - 1 ))

# Numero di web server da configurare
n_web_server=$(./jq ".web_server | length" $file)
n_web_server=$(( n_web_server - 1 ))


# Configurazione tof
if [ $n_tof -gt -1 ]; then
	for i in $(seq 0 $n_tof) ; do
		
		# Nome della macchina
		nome_macchina=$(./jq -r ".tof[$i].nome_macchina" $file)

		# Creazione della directory e copia file di configurazione
		files_configuration_tof_spine_leaf

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".tof[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))
		
		# Configurazione lab.conf
		config_file_lab "tof"

		# Image definition and Multipath policy in lab.conf
		image_mpath_definition $nome_macchina "tof" "$nome_lab/image.conf" "$nome_lab/mpath_policy.conf"
		
		# Creazione e configurazione file .startup
		startup_generator "tof"
		

		# Configurazione file bgpd
		# AS number macchina
		as_number=$(./jq -r ".tof[$i].as_number" $file)
		# Router ID macchina
		router_id=$(./jq -r ".tof[$i].router_id" $file)

		cat "$cartella_configurazioni/file_conf/tof.conf" >> "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/as_number/$as_number/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/router_id/$router_id/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"

	done
fi


# Configurazione spine
if [ $n_spine -gt -1 ]; then
	for i in $(seq 0 $n_spine) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".spine[$i].nome_macchina" $file)

		# Creazione della directory e copia file di configurazione
		files_configuration_tof_spine_leaf

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".spine[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))
		
		# Configurazione lab.conf
		config_file_lab "spine"

		# Image definition and Multipath policy in lab.conf
		image_mpath_definition $nome_macchina "spine" "$nome_lab/image.conf" "$nome_lab/mpath_policy.conf"
		
		# Creazione e configurazione file .startup
		startup_generator "spine"


		# Configurazione file bgpd
		# AS number macchina
		as_number=$(./jq -r ".spine[$i].as_number" $file)
		# Router ID macchina
		router_id=$(./jq -r ".spine[$i].router_id" $file)

		cat "$cartella_configurazioni/file_conf/spine.conf" >> "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/as_number/$as_number/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/router_id/$router_id/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"

	done
fi


# Configurazione leaf
if [ $n_leaf -gt -1 ]; then
	for i in $(seq 0 $n_leaf) ; do
		
		# Nome della macchina
		nome_macchina=$(./jq -r ".leaf[$i].nome_macchina" $file)

		# Creazione della directory e copia file di configurazione
		files_configuration_tof_spine_leaf

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".leaf[$i].numero_interfacce_totali" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))
		numero_interfacce_startup=$(./jq ".leaf[$i].numero_interfacce_layer_2" $file)
		
		# Configurazione lab.conf
		config_file_lab "leaf"

		# Image definition and Multipath policy in lab.conf
		image_mpath_definition $nome_macchina "leaf" "$nome_lab/image.conf" "$nome_lab/mpath_policy.conf"

		numero_interfacce=$(( numero_interfacce - numero_interfacce_startup))
		# Creazione e configurazione file .startup
		startup_generator "leaf"


		# Configurazione file bgpd
		# AS number macchina
		as_number=$(./jq -r ".leaf[$i].as_number" $file)
		# Router ID macchina
		router_id=$(./jq -r ".leaf[$i].router_id" $file)
		# Loopback
		loopback=$(./jq -r ".leaf[$i].loopback" $file)

		cat "$cartella_configurazioni/file_conf/leaf.conf" >> "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/as_number/$as_number/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/router_id/$router_id/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"
		sed -i "" "s/loopback_ip/$loopback/g" "$nome_lab/$nome_macchina/etc/frr/bgpd.conf"

		sed -i "" "s/loopback_ip/$loopback/g" $file_startup

	done
fi


# Configurazione data centers server to container 
if [ $n_server -gt -1 ]; then
	for i in $(seq 0 $n_server) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".server[$i].nome_macchina" $file)

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".server[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))

		# Configurazione lab.conf
		config_file_lab "server"

		# Image definition and Multipath policy in lab.conf
		image_mpath_definition $nome_macchina server "$nome_lab/image.conf"
		
		# Creazione e configurazione file .startup
		file_startup="$nome_lab/$nome_macchina.startup"
		touch $file_startup

		cat "$cartella_configurazioni/file_conf/server.startup" >> $file_startup

	done
fi


# Configurazione container
# se non sono presenti container e le leaf collegate a server
# per server utilizzare questa configurazione
if [ $n_container -gt -1 ]; then
	for i in $(seq 0 $n_container) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".container_web_server[$i].nome_macchina" $file)

		# Creazione file .startup
		file_startup="$nome_lab/$nome_macchina.startup"
		touch $file_startup

		files_configuration_container_web_server

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".container_web_server[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))

		# Configurazione lab.conf
		config_file_lab "container_web_server"

		# Image definition and Multipath policy in lab.conf
		image_mpath_definition $nome_macchina "container" "$nome_lab/image.conf"
		
		# Configurazione interfacce in .startup
		startup_generator "container_web_server"
		
	done
fi


# Configurazione load balancer
if [ $n_load_balancer -gt -1 ]; then
	for i in $(seq 0 $n_load_balancer) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".load_balancer[$i].nome_macchina" $file)

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".load_balancer[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))


		# Configurazione lab.conf
		config_file_lab "load_balancer"
		
		# Creazione e configurazione file .startup
		startup_generator "load_balancer"

	done
fi


# Configurazione macchine con protocolli di routing
if [ $n_macchine -gt -1 ]; then
	for i in $(seq 0 $n_macchine) ; do
		
		# Nome della macchina
		nome_macchina=$(./jq -r ".macchine[$i].nome_macchina" $file)
		
		# Creazione della directory e copia file di configurazione
		files_configuration_macchine

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".macchine[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))
		
		# Configurazione lab.conf
		config_file_lab "macchine"
		
		# Creazione e configurazione file .startup
		startup_generator "macchine"
		
		# Configurazione file /etc/frr/deamons
		m=$(./jq ".macchine[$i].protocolli | length" $file)
		m=$(( m - 1 ))
		for j in $(seq 0 $m) ; do
		
			protocollo=$(./jq -r ".macchine[$i].protocolli[$j]" $file)
			if test $protocollo = "BGP" ; then
				
				sed -i "" "s/bgpd=no/bgpd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/frr/file_conf/bgp.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"

			elif test $protocollo = "OSPF" ; then
				# sed -i "" -> aggiungere stringa vuota in OS X
				sed -i "" "s/ospfd=no/ospfd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/frr/file_conf/ospf.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"
			
			elif test $protocollo = "RIP" ; then
		
				sed -i "" "s/ripd=no/ripd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/frr/file_conf/rip.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"
			
			fi
			
		done

	done
fi


# Configurazione client - solo file di startup 
if [ $n_client -gt -1 ]; then
	for i in $(seq 0 $n_client) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".client[$i].nome_macchina" $file)

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".client[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))


		# Configurazione lab.conf
		config_file_lab "client"
		
		# Creazione e configurazione file .startup
		startup_generator "client"

	done
fi


# Configurazione web server
if [ $n_web_server -gt -1 ]; then
	for i in $(seq 0 $n_web_server) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".web_server[$i].nome_macchina" $file)

		# Creazione della directory e copia file di configurazione
		files_configuration_container_web_server

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".web_server[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))

		# Configurazione lab.conf
		config_file_lab "web_server"
		
		# Configurazione interfacce in .startup
		startup_generator "web_server"
		
	done
fi


cat "$nome_lab/image.conf" >> "$nome_lab/lab.conf"
echo "" >> "$nome_lab/lab.conf"
cat "$nome_lab/mpath_policy.conf" >> "$nome_lab/lab.conf"

rm "$nome_lab/image.conf" "$nome_lab/mpath_policy.conf"

