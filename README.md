# Kong api-monetization Plugin
## Overview
This plugin will help to Monetize your APIs effortlessly , offering flexible subscription plans including Lite and Premium options. Seamlessly manage access and generate revenue from your API services while providing your customers with tailored plans that meet their needs.
Maximize your API's potential with a powerful, easy-to-implement monetization solution.
Based on the selected subscription plan, the plugin controls and manages access to your APIs, ensuring users only consume the services according to their chosen plan.
## Tested in Kong Release
Kong Enterprise 2.8.2.1

## Installation
### Recommended
```
$ git clone https://github.com/satyajitsial/api-monetization
$ cd api-monetization
$ luarocks make kong-plugin-api-monetization-0.1.0-1.rockspec
```
### Other

```
$ git clone https://github.com/satyajitsial/api-monetization
$ cd api-monetization
$ luarocks install kong-plugin-api-monetization-0.1.0-1.all.rock
```
After Installing the Plugin using any of the above steps . Add the Plugin Name in Kong.conf

```
plugins = bundled,api-monetization

```
### Restart Kong

```
kong restart

```
# Configuration Reference

## Enable the plugin on a Consumer

### Admin-API
For example, configure this plugin on a consumer by making the following request:
```		
  curl -i -X POST http://localhost:8001/consumers/<CONSUMER_ID>/plugins \
  --data "name=api-monetization" \
  --data "config.subscriptionPlan=Premium/Lite" \
  --data "config.subscriptionPackage=Monthly/Yearly" \
  --data "config.email_address=<Customer_Email>" \
  --data "config.Private_key=<PRIVATE_KEY>"
```
### Declarative(YAML)
For example, configure this plugin on a consumer by adding this section to your declarative configuration file:
```			
  - consumers:
  - username: <CONSUMER_NAME>
    plugins:
      - name: api-monetization
       config:
        subscriptionPlan: Premium/Lite
        subscriptionPackage: Monthly/Yearly
        email_address: <Customer_Email>
        Private_key: <PRIVATE_KEY>
```
## Parameters

| FORM PARAMETER	     														| DESCRIPTION										  													|
| ----------- 																		| -----------																								|
| name<br>Type:string  														|  The name of the plugin to use, in this case skip-plugins |										  |
| config.subscriptionPlan<br>Type:string              |  Accepts a subscription plan either Lite/Premium|
| config.subscriptionPackage<br>Type:string              |  Accepts a subscription Package either Monthly/Yearly|
| config.email_address<br>Type:string              |  Customer Email|
| config.Private_key<br>Type:string              |  Accepts a Private Key|

## Error code

| Request	     														| Response Code				 |       Response									|
| ----------- 														| -----------					 | -----------	                  |
| Input Plugin name is empty or space  		|  403								 | "message": "You are not allowed to use the service"|


## Known Limitation
The Plugin can be enhanced to support differnent API monitization Subscription Plans .


## Contributors
Developed By : Satyajit.Sial@VERIFONE.com <br>
Designed By  : DhavalM1@VERIFONE.com, Prema.Namasivayam@VERIFONE.com
			         