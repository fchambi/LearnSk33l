#!/bin/bash

# Seed test data for Sk33L platform
# This script uses cast send to interact with deployed contracts

echo "🌱 Seeding test data for Sk33L..."

# Read deployed contract addresses
DEPLOY_FILE="broadcast/Deploy.s.sol/31337/run-latest.json"

if [ ! -f "$DEPLOY_FILE" ]; then
    echo "❌ Error: Deployment file not found. Please run 'yarn deploy' first."
    exit 1
fi

# Extract addresses using jq or grep
REPUTATION=$(cat "$DEPLOY_FILE" | grep -o '"contractAddress":"0x[^"]*"' | head -1 | cut -d'"' -f4)
SUBSCRIPTION=$(cat "$DEPLOY_FILE" | grep -o '"contractAddress":"0x[^"]*"' | sed -n '2p' | cut -d'"' -f4)
COURSE_REGISTRY=$(cat "$DEPLOY_FILE" | grep -o '"contractAddress":"0x[^"]*"' | sed -n '3p' | cut -d'"' -f4)

echo ""
echo "📋 Using deployed contracts:"
echo "  Reputation: $REPUTATION"
echo "  EducatorSubscription: $SUBSCRIPTION"
echo "  CourseRegistry: $COURSE_REGISTRY"
echo ""

# Anvil account private keys
EDUCATOR1_KEY="0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
EDUCATOR2_KEY="0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"

RPC_URL="http://localhost:8545"

echo "👨‍🏫 Setting up Educator 1 (0x7099...79C8)..."

# Educator 1: Set monthly price to 0.01 ETH
cast send $SUBSCRIPTION "setMonthlyPrice(uint256)" 10000000000000000 \
  --private-key $EDUCATOR1_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1

echo "  ✅ Set price: 0.01 ETH/month"

# Educator 1: Create 3 courses
cast send $COURSE_REGISTRY "createCourse(string)" "ipfs://QmWeb3CourseIntroduction" \
  --private-key $EDUCATOR1_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Created course 1: Web3 Introduction"

cast send $COURSE_REGISTRY "createCourse(string)" "ipfs://QmSolidityBasics" \
  --private-key $EDUCATOR1_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Created course 2: Solidity Basics"

cast send $COURSE_REGISTRY "createCourse(string)" "ipfs://QmSmartContractSecurity" \
  --private-key $EDUCATOR1_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Created course 3: Smart Contract Security"

echo ""
echo "👨‍🏫 Setting up Educator 2 (0x3C44...293BC)..."

# Educator 2: Set monthly price to 0.02 ETH
cast send $SUBSCRIPTION "setMonthlyPrice(uint256)" 20000000000000000 \
  --private-key $EDUCATOR2_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Set price: 0.02 ETH/month"

# Educator 2: Create 2 courses
cast send $COURSE_REGISTRY "createCourse(string)" "ipfs://QmDeFiMasterclass" \
  --private-key $EDUCATOR2_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Created course 1: DeFi Masterclass"

cast send $COURSE_REGISTRY "createCourse(string)" "ipfs://QmNFTDevelopment" \
  --private-key $EDUCATOR2_KEY \
  --rpc-url $RPC_URL > /dev/null 2>&1
echo "  ✅ Created course 2: NFT Development"

echo ""
echo "✅ Seeding complete!"
echo ""
echo "📊 Test data ready:"
echo "  • Educator 1: 0.01 ETH/month, 3 courses"
echo "  • Educator 2: 0.02 ETH/month, 2 courses"
echo ""
echo "🚀 Ready to start the frontend!"

