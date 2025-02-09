BASE_MAINNET_RPC_URL = "https://mainnet.base.org"

all :  remove install build

clean :; forge clean

remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit

update :; forge update

compile :; forge compile

build :; forge build

test :; forge test

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

precommit :; forge fmt && git add .

test-all :; forge test --fork-url $(BASE_MAINNET_RPC_URL)

test-yield-strategy-manager :; forge test --match-contract YieldStrategyManagerTest

test-morpho-base-strategy :; forge test --match-contract MorphoBaseStrategyTest --fork-url $(BASE_MAINNET_RPC_URL)

test-aave-v3-base-strategy :; forge test --match-contract AaveV3BaseStrategyTest --fork-url $(BASE_MAINNET_RPC_URL)