#!/bin/bash

# Nel file workspace.conf le interfacce inserite in ordine di eth
# File JSON di configurazione
file="workspace.conf"

# Nome della cartella che contiene il lab
nome_lab=$(./jq -r ".nome_lab" $file)

# Versione generatore del lab
generator_version=$(./jq -r ".generator_version" $file)
echo "Workspace conf generator version: $generator_version"

# Creazione cartella lab
mkdir $nome_lab
touch "$nome_lab/lab.conf"

# Creazione cartella test 
mkdir "test_lab"
touch "test_lab/all_ip.txt"


# Nome cartella da cui prendere i template delle configurzioni
cartella_configurazioni=$(./jq -r ".cartella_configurazioni" $file)

# Copia file ping di test
cp "$cartella_configurazioni/test_ping.sh" "test_lab"

# Numero di macchine da configurare
n_macchine=$(./jq ".macchine | length" $file)
n_macchine=$(( n_macchine - 1 ))

# Numero di client da configurare
n_client=$(./jq ".client | length" $file)
n_client=$(( n_client - 1 ))

# Numero di web server da configurare
n_web_server=$(./jq ".web_server | length" $file)
n_web_server=$(( n_web_server - 1 ))


# Per ogni macchina
if [ $n_macchine -gt -1 ]; then
	for i in $(seq 0 $n_macchine) ; do
		
		# Nome della macchina
		nome_macchina=$(./jq -r ".macchine[$i].nome_macchina" $file)
		
		# Creazione file .startup
		file_startup="$nome_lab/$nome_macchina.startup"
		touch $file_startup
		
		# Creazione della directory nome_macchina/etc/frr 
		dir="$nome_lab/$nome_macchina/etc/frr"
		mkdir "$nome_lab/$nome_macchina"
		mkdir "$nome_lab/$nome_macchina/etc"
		mkdir "$nome_lab/$nome_macchina/etc/frr"
		
		# I template dei file di configurazione vengono copiati nella directory /etc/frr
		cp "$cartella_configurazioni/vtysh.conf" "$nome_lab/$nome_macchina/etc/frr"
		cp "$cartella_configurazioni/frr.conf" "$nome_lab/$nome_macchina/etc/frr"
		cp "$cartella_configurazioni/daemons" "$nome_lab/$nome_macchina/etc/frr"

		# Configurazione file /etc/frr/vtysh.conf
		sed -i "" "s/nome_host/$nome_macchina-frr/g" "$nome_lab/$nome_macchina/etc/frr/vtysh.conf"
		
		# Macchina corrente commento /etc/frr/frr.conf
		sed -i "" "s/nome_host/$nome_macchina/g" "$nome_lab/$nome_macchina/etc/frr/frr.conf"

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".macchine[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))
		
		# Configurazione lab.conf
		for k in $(seq 0 $numero_interfacce) ; do
			
			dominio=$(./jq -r ".macchine[$i].interfacce[$k].dominio" $file)
			comando="$nome_macchina[$k]="'"'"$dominio"'"'
			echo $comando >> "$nome_lab/lab.conf"
		
		done
		echo "" >> "$nome_lab/lab.conf"
		
		# Configurazione interfacce in .startup
		for k in $(seq 0 $numero_interfacce) ; do
			
			ip=$(./jq -r ".macchine[$i].interfacce[$k].ip" $file)
			cidr=$(./jq -r ".macchine[$i].interfacce[$k].cidr" $file)
			comando="/sbin/ifconfig eth"$k" $ip""/""$cidr ""up"
			echo $comando >> $file_startup
		
		done
		echo "/etc/init.d/frr start" >> $file_startup
		
		# Configurazione file /etc/frr/deamons
		m=$(./jq ".macchine[$i].protocolli | length" $file)
		m=$(( m - 1 ))
		for j in $(seq 0 $m) ; do
		
			protocollo=$(./jq -r ".macchine[$i].protocolli[$j]" $file)
			if test $protocollo = "BGP" ; then
				
				sed -i "" "s/bgpd=no/bgpd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/file_conf/bgp.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"

			elif test $protocollo = "OSPF" ; then
				# sed -i "" -> aggiungere stringa vuota in OS X
				sed -i "" "s/ospfd=no/ospfd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/file_conf/ospf.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"
			
			elif test $protocollo = "RIP" ; then
		
				sed -i "" "s/ripd=no/ripd=yes/g" "$nome_lab/$nome_macchina/etc/frr/daemons"
				cat "$cartella_configurazioni/file_conf/rip.conf" >> "$nome_lab/$nome_macchina/etc/frr/frr.conf"
			
			fi
			
		done

		# File di test
		for k in $(seq 0 $numero_interfacce) ; do
			ip=$(./jq -r ".macchine[$i].interfacce[$k].ip" $file)
			dominio=$(./jq -r ".macchine[$i].interfacce[$k].dominio" $file)
			
			if [ ! -f "test_lab/$dominio.txt" ]; then
	    		touch "test_lab/$dominio.txt"
			fi

			echo $ip $nome_macchina >> "test_lab/$dominio.txt"
			echo $ip $nome_macchina >> "test_lab/all_ip.txt"

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
		for k in $(seq 0 $numero_interfacce) ; do
			
			dominio=$(./jq -r ".client[$i].interfacce[$k].dominio" $file)
			comando="$nome_macchina[$k]="'"'"$dominio"'"'
			echo $comando >> "$nome_lab/lab.conf"
		
		done
		echo "" >> "$nome_lab/lab.conf"
		
		# Creazione file .startup
		file_startup="$nome_lab/$nome_macchina.startup"
		touch $file_startup

		# Configurazione interfacce in .startup
		for k in $(seq 0 $numero_interfacce) ; do
			
			ip=$(./jq -r ".client[$i].interfacce[$k].ip" $file)
			cidr=$(./jq -r ".client[$i].interfacce[$k].cidr" $file)
			comando="/sbin/ifconfig eth"$k" $ip""/""$cidr ""up"
			echo $comando >> $file_startup
		
		done


		# File di test
		for k in $(seq 0 $numero_interfacce) ; do
			ip=$(./jq -r ".client[$i].interfacce[$k].ip" $file)
			dominio=$(./jq -r ".client[$i].interfacce[$k].dominio" $file)
			
			if [ ! -f "test_lab/$dominio.txt" ]; then
	    		touch "test_lab/$dominio.txt"
			fi

			echo $ip $nome_macchina >> "test_lab/$dominio.txt"
			echo $ip $nome_macchina >> "test_lab/all_ip.txt"

		done
	done
fi



# Configurazione web server
if [ $n_web_server -gt -1 ]; then
	for i in $(seq 0 $n_web_server) ; do

		# Nome della macchina
		nome_macchina=$(./jq -r ".web_server[$i].nome_macchina" $file)

		# Creazione della directory nome_macchina/var/www/html 
		mkdir "$nome_lab/$nome_macchina"
		mkdir "$nome_lab/$nome_macchina/var"
		mkdir "$nome_lab/$nome_macchina/var/www"
		mkdir "$nome_lab/$nome_macchina/var/www/html"
		cp "$cartella_configurazioni/index.html" "$nome_lab/$nome_macchina/var/www/html"

		# Server corrente nel file html
		sed -i "" "s/\[nome_server\]/$nome_macchina/g" "$nome_lab/$nome_macchina/var/www/html/index.html"

		# Numero di interfacce da configurare
		numero_interfacce=$(./jq ".web_server[$i].numero_interfacce" $file)
		numero_interfacce=$(( numero_interfacce - 1 ))

		# Configurazione lab.conf
		for k in $(seq 0 $numero_interfacce) ; do
			
			dominio=$(./jq -r ".web_server[$i].interfacce[$k].dominio" $file)
			comando="$nome_macchina[$k]="'"'"$dominio"'"'
			echo $comando >> "$nome_lab/lab.conf"
		
		done
		echo "" >> "$nome_lab/lab.conf"
		
		# Creazione file .startup
		file_startup="$nome_lab/$nome_macchina.startup"
		touch $file_startup

		# Configurazione interfacce in .startup
		for k in $(seq 0 $numero_interfacce) ; do
			
			ip=$(./jq -r ".web_server[$i].interfacce[$k].ip" $file)
			cidr=$(./jq -r ".web_server[$i].interfacce[$k].cidr" $file)
			comando="/sbin/ifconfig eth"$k" $ip""/""$cidr ""up"
			echo $comando >> $file_startup
		
		done
		echo $"route add default gw <ip_gateway> dev <eth>" >> $file_startup
		echo "/etc/init.d/apache2 start" >> $file_startup
		

		# File di test
		for k in $(seq 0 $numero_interfacce) ; do
			ip=$(./jq -r ".web_server[$i].interfacce[$k].ip" $file)
			dominio=$(./jq -r ".web_server[$i].interfacce[$k].dominio" $file)
			
			if [ ! -f "test_lab/$dominio.txt" ]; then
	    		touch "test_lab/$dominio.txt"
			fi

			echo $ip $nome_macchina >> "test_lab/$dominio.txt"
			echo $ip $nome_macchina >> "test_lab/all_ip.txt"

		done
	done
fi