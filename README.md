# Internet and Data Centers

This repository contains the lectures and labs of 2022-2023 Internet and data Centers course at Roma Tre University.

## [Exercises](exercises)
This folder contains labs and intermediate tests carried out during the course. 

## [Lectures](lectures)
This folder contains the 2022-23 lectures of the course.

## [Script](script)
This folder contains scripts that I wrote to generate the labs starting from a configuration file. The scripts only generate the folders and startup files (containing interfaces only) for the lab machines. After generating the lab it is necessary to configure the protocols of the machines and the startup files (if necessary, example *leaf* in data centers).

In the lab folders there is the file `workspace.conf` used to generate the lab.

To generate lab edit file `workspace.conf` and run `bash makeWorkspace.sh`.

### Example `workspace.conf` file:
```json
{
	"generator_version": "2",
	"nome_lab": "lab_prova",
	"cartella_configurazioni": "file_configurazione",
	"macchine": [
		{
			"nome_macchina": "as9r1",
			"protocolli": [ "BGP" ],
			"numero_interfacce": 2,
			"interfacce": [
				{
					"ip": "9.9.9.1",
					"cidr": "24",
					"dominio": "G"
				},
				{
					"ip": "89.89.89.2",
					"cidr": "24",
					"dominio": "H"
				}
			]
			
		},
		{
			"nome_macchina": "as8r1",
			"protocolli": [ "BGP" ],
			"numero_interfacce": 2,
			"interfacce": [
				{
					"ip": "8.8.8.1",
					"cidr": "24",
					"dominio": "L"
				},
				{
					"ip": "89.89.89.1",
					"cidr": "24",
					"dominio": "H"
				}
			]
			
		}
	],
	"client": [
		{
			"nome_macchina": "client",
			"numero_interfacce": 1,
			"interfacce": [
				{
					"ip": "8.8.8.8",
					"cidr": "24",
					"dominio": "L"
				}
			]	
		}
	],
	"web_server": [
	]
}
```
