#!/bin/sh

EURO_ISSUER_NAME=euro-issuer
EURO_NAME=euro

TOKEN_ISSUER_NAME=token-issuer
TOKEN_NAME=token

CBDC_ISSUER_NAME=cbdc-issuer
CBDC_NAME=cbdc

# Creates a issuer with name and token for a given node by a given node
# Takes 4 args (name 0f issuer, name of token, node to create key, node to submit transaction)
createIssuer() {
	echo "Creating issuer key on $1 on node $3\n"

	# create the issuer key
	docker exec -e ISSUER_NAME=$1 $3 /bin/sh -c 'poacli keys add $(echo $ISSUER_NAME) --keyring-backend test'
	
	# get the address of the issuer key
	eval ADDRESS=$(docker exec -e ISSUER_NAME=$1 $3 /bin/sh -c 'poacli keys show $(echo $ISSUER_NAME) -a --keyring-backend test')

	echo "Creating issuer with name $1 and token $2: on node $4\n"
	
	## create the issuer token pairing
	docker exec -e ADDRESS=$ADDRESS -e ISSUER_NAME=$1 -e TOKEN_NAME=$2 $4 /bin/sh -c 'poacli tx issuer create-issuer $(echo $ISSUER_NAME) $(echo $ADDRESS) $(echo $TOKEN_NAME) 100000000000 -y --trust-node --from validator --chain-id cash --keyring-backend test'
	
	sleep 5
}

# Queries an account for it balance and prints to screen
# issuer name poadnode1
queryAccount() {
	docker exec -e ISSUER_NAME=$1 $2 /bin/sh -c 'poacli query account $(poacli keys show $(echo $ISSUER_NAME) -a --keyring-backend test)'
}

# Mints tokens for a given issuer and token
# issuer name, issuer token, and node
mintTokens() {
	docker exec -e ISSUER_NAME=$1 -e TOKEN_NAME=$2 $3 /bin/sh -c 'poacli tx issuer mint-token $(echo $TOKEN_NAME) 100000000000 -y --trust-node --from $(echo $ISSUER_NAME) --chain-id cash --keyring-backend test'
	sleep 5
}

# Burn tokens for a given issuer and token
# issuer name, issuer token, and node
burnTokens() {
	docker exec -e ISSUER_NAME=$1 -e TOKEN_NAME=$2 $3 /bin/sh -c 'poacli tx issuer burn-token $(echo $TOKEN_NAME) 100000000000 -y --trust-node --from $(echo $ISSUER_NAME) --chain-id cash --keyring-backend test'
	sleep 5
}

# Send tokens for a given issuer and token
# issuer name, issuer token, and node
sendTokens() {
	eval ADDRESS=$(docker exec -e ISSUER_NAME=$3 $4 /bin/sh -c 'poacli keys show $(echo $ISSUER_NAME) -a --keyring-backend test')
	
	docker exec -e ISSUER_NAME=$1 -e TOKEN_NAME=$2 -e TO_ADDRESS=$ADDRESS $5 /bin/sh -c 'poacli tx send $(poacli keys show $(echo $ISSUER_NAME) -a --keyring-backend test) $(echo $TO_ADDRESS) 500000000$(echo $TOKEN_NAME) -y --from $(echo $ISSUER_NAME) --trust-node --chain-id cash --keyring-backend test'
	sleep 5
}


###############################################################################
###                           STEP 1		                            ###
###############################################################################

# Create issuers

echo "Creating issuer for eurotoken\n"
createIssuer $EURO_ISSUER_NAME $EURO_NAME poadnode1 poadnode0 

echo "Creating issuer for cdbc\n"
createIssuer $CBDC_ISSUER_NAME $CBDC_NAME poadnode1 poadnode0 

echo "Creating issuer for token\n"
createIssuer $TOKEN_ISSUER_NAME $TOKEN_NAME poadnode1 poadnode0 

###############################################################################
###                           STEP 2		                            ###
###############################################################################

# Mint, Burn and transfer tokens

# Mint euro  
mintTokens $EURO_ISSUER_NAME $EURO_NAME poadnode1

# echo "Issuer should have 200000000000 eurotoken's\n"
queryAccount $EURO_ISSUER_NAME poadnode1

# Burn euro
burnTokens $EURO_ISSUER_NAME $EURO_NAME poadnode1

# echo "Issuer should have 100000000000 eurotoken's\n"
queryAccount $EURO_ISSUER_NAME poadnode1

# Transfer tokens between issuers  
sendTokens $TOKEN_ISSUER_NAME $TOKEN_NAME $EURO_ISSUER_NAME poadnode1 poadnode1
sendTokens $CBDC_ISSUER_NAME $CBDC_NAME $EURO_ISSUER_NAME poadnode1 poadnode1

sendTokens $EURO_ISSUER_NAME $EURO_NAME $TOKEN_ISSUER_NAME poadnode1 poadnode1
sendTokens $CBDC_ISSUER_NAME $CBDC_NAME $TOKEN_ISSUER_NAME poadnode1 poadnode1

sendTokens $TOKEN_ISSUER_NAME $TOKEN_NAME $CBDC_ISSUER_NAME poadnode1 poadnode1
sendTokens $EURO_ISSUER_NAME $EURO_NAME $CBDC_ISSUER_NAME poadnode1 poadnode1
