# rogue_devkit
We are using traefik as a reverse proxy. The proxy configurations expect
domain names for the different services deployed behind traefik. In order 
to properly sub-domain them, you need to set the main domain as shown below:
`export DOMAIN=domain`

You also need to set the main directory where all docker volumes will be set.
`export DEV_DATA_PREFIX=prefix`

In addition, a local dns entry has to be set in the hosts file of your system.
The main domain and all subdomains have to point to the same IP address. If 
you are running on a local system, this entry has to poin to the loopback address

## Swarm init
`make swarm_init`

## Network
`make traefik_network`

## Set the base domain
Set the domain with `export DOMAIN={domain}`

# Volume Directories
`make env=LOCAL mount_prep`
