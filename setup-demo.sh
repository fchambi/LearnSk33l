#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║          🚀 Sk33L Platform - Setup Demo                   ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if chain is running
echo -e "${YELLOW}Checking if local chain is running...${NC}"
if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' http://localhost:8545 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Local chain is running${NC}"
else
    echo -e "${YELLOW}⚠️  Local chain is not running${NC}"
    echo -e "${YELLOW}Please run 'yarn chain' in another terminal first${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 1: Deploying Smart Contracts...${NC}"
cd packages/foundry
make deploy
cd ../..

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}❌ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Contracts deployed successfully${NC}"
echo ""

echo -e "${BLUE}Step 2: Seeding test data...${NC}"
cd packages/foundry
./seed-data.sh
cd ../..

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}❌ Seeding failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Test data seeded successfully${NC}"
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║                  ✅ SETUP COMPLETE!                        ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}📊 Pre-loaded Test Data:${NC}"
echo ""
echo -e "${YELLOW}Educator 1:${NC} 0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
echo -e "  - Monthly Price: 0.01 ETH"
echo -e "  - Courses: 3"
echo ""
echo -e "${YELLOW}Educator 2:${NC} 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC"
echo -e "  - Monthly Price: 0.02 ETH"
echo -e "  - Courses: 2"
echo ""

echo -e "${GREEN}🚀 Next Steps:${NC}"
echo ""
echo -e "1. Start the frontend:"
echo -e "   ${BLUE}yarn start${NC}"
echo ""
echo -e "2. Open your browser:"
echo -e "   ${BLUE}http://localhost:3000${NC}"
echo ""
echo -e "3. Connect your wallet and start testing!"
echo ""
echo -e "${GREEN}📚 For more information, see:${NC}"
echo -e "   ${BLUE}README.md${NC}"
echo ""

