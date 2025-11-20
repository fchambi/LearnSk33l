#!/bin/bash

# 🧪 Script de Testing para Contratos Desplegados en Scroll Sepolia

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🧪 Testing Sk33L en Scroll Sepolia  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar que el archivo de deployment existe
if [ ! -f "deployments/534351.json" ]; then
    echo -e "${RED}❌ No se encontró deployments/534351.json${NC}"
    echo -e "${YELLOW}Primero despliega los contratos con: ./deploy-scroll.sh${NC}"
    exit 1
fi

# Leer direcciones desde el archivo de deployment
echo -e "${BLUE}📋 Leyendo direcciones de contratos...${NC}"

REPUTATION=$(cat deployments/534351.json | grep -o '"Reputation"[^}]*' | grep -o '0x[a-fA-F0-9]*' | head -1)
SUBSCRIPTION=$(cat deployments/534351.json | grep -o '"EducatorSubscription"[^}]*' | grep -o '0x[a-fA-F0-9]*' | head -1)
COURSE=$(cat deployments/534351.json | grep -o '"CourseRegistry"[^}]*' | grep -o '0x[a-fA-F0-9]*' | head -1)
LEARN=$(cat deployments/534351.json | grep -o '"LearnToEarn"[^}]*' | grep -o '0x[a-fA-F0-9]*' | head -1)

if [ -z "$REPUTATION" ] || [ -z "$SUBSCRIPTION" ] || [ -z "$COURSE" ] || [ -z "$LEARN" ]; then
    echo -e "${RED}❌ No se pudieron leer todas las direcciones${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Direcciones encontradas:${NC}"
echo -e "  Reputation:            $REPUTATION"
echo -e "  EducatorSubscription:  $SUBSCRIPTION"
echo -e "  CourseRegistry:        $COURSE"
echo -e "  LearnToEarn:           $LEARN"
echo ""

# Cargar configuración
source .env

if [ -z "$ETH_KEYSTORE_ACCOUNT" ]; then
    echo -e "${RED}❌ ETH_KEYSTORE_ACCOUNT no configurado en .env${NC}"
    exit 1
fi

# Obtener dirección del deployer
DEPLOYER=$(cast wallet address --account $ETH_KEYSTORE_ACCOUNT 2>/dev/null || echo "")
if [ -z "$DEPLOYER" ]; then
    echo -e "${RED}❌ No se pudo obtener dirección del deployer${NC}"
    exit 1
fi

echo -e "${BLUE}👤 Deployer: $DEPLOYER${NC}"
echo ""

# Verificar balance
BALANCE=$(cast balance $DEPLOYER --rpc-url scrollSepolia)
BALANCE_ETH=$(cast --to-unit $BALANCE ether)
echo -e "${BLUE}💰 Balance: $BALANCE_ETH ETH${NC}"
echo ""

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}   Iniciando Tests...${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Test 1: Verificar owner de Reputation
echo -e "${YELLOW}[Test 1/8]${NC} Verificando owner de Reputation..."
OWNER=$(cast call $REPUTATION "owner()" --rpc-url scrollSepolia)
OWNER_FORMATTED=$(cast --to-checksum-address $OWNER)
if [ "$OWNER_FORMATTED" == "$DEPLOYER" ]; then
    echo -e "${GREEN}✅ Owner correcto: $OWNER_FORMATTED${NC}"
else
    echo -e "${RED}❌ Owner incorrecto${NC}"
    exit 1
fi
echo ""

# Test 2: Establecer precio mensual
echo -e "${YELLOW}[Test 2/8]${NC} Estableciendo precio mensual (0.01 ETH)..."
TX=$(cast send $SUBSCRIPTION \
    "setMonthlyPrice(uint256)" 10000000000000000 \
    --rpc-url scrollSepolia \
    --account $ETH_KEYSTORE_ACCOUNT \
    2>&1)

if echo "$TX" | grep -q "blockHash"; then
    echo -e "${GREEN}✅ Precio establecido${NC}"
    TX_HASH=$(echo "$TX" | grep "transactionHash" | awk '{print $2}')
    echo -e "   TX: $TX_HASH"
else
    echo -e "${RED}❌ Error estableciendo precio${NC}"
    exit 1
fi
echo ""

# Test 3: Verificar precio
echo -e "${YELLOW}[Test 3/8]${NC} Verificando precio mensual..."
PLAN=$(cast call $SUBSCRIPTION "plans(address)(uint256,bool)" $DEPLOYER --rpc-url scrollSepolia)
PRICE=$(echo $PLAN | awk '{print $1}')
ACTIVE=$(echo $PLAN | awk '{print $2}')

if [ "$PRICE" == "10000000000000000" ] && [ "$ACTIVE" == "true" ]; then
    echo -e "${GREEN}✅ Precio verificado: 0.01 ETH, Plan activo${NC}"
else
    echo -e "${RED}❌ Precio o estado incorrecto${NC}"
    exit 1
fi
echo ""

# Test 4: Crear curso
echo -e "${YELLOW}[Test 4/8]${NC} Creando curso de prueba..."
METADATA="ipfs://QmSkillTestCourse$(date +%s)"
TX=$(cast send $COURSE \
    "createCourse(string)" "$METADATA" \
    --rpc-url scrollSepolia \
    --account $ETH_KEYSTORE_ACCOUNT \
    2>&1)

if echo "$TX" | grep -q "blockHash"; then
    echo -e "${GREEN}✅ Curso creado${NC}"
    TX_HASH=$(echo "$TX" | grep "transactionHash" | awk '{print $2}')
    echo -e "   TX: $TX_HASH"
    echo -e "   Metadata: $METADATA"
else
    echo -e "${RED}❌ Error creando curso${NC}"
    exit 1
fi
echo ""

# Test 5: Verificar curso
echo -e "${YELLOW}[Test 5/8]${NC} Verificando curso creado..."
NEXT_ID=$(cast call $COURSE "nextCourseId()(uint256)" --rpc-url scrollSepolia)
echo -e "   Siguiente ID: $NEXT_ID"

COURSE_DATA=$(cast call $COURSE "getCourse(uint256)(uint256,address,string,bool)" 0 --rpc-url scrollSepolia 2>/dev/null || echo "")
if [ ! -z "$COURSE_DATA" ]; then
    echo -e "${GREEN}✅ Curso verificado (ID: 0)${NC}"
else
    echo -e "${RED}❌ No se pudo verificar curso${NC}"
fi
echo ""

# Test 6: Verificar autorización en Reputation
echo -e "${YELLOW}[Test 6/8]${NC} Verificando autorizaciones..."
SUB_AUTH=$(cast call $REPUTATION "authorized(address)(bool)" $SUBSCRIPTION --rpc-url scrollSepolia)
LEARN_AUTH=$(cast call $REPUTATION "authorized(address)(bool)" $LEARN --rpc-url scrollSepolia)

if [ "$SUB_AUTH" == "true" ] && [ "$LEARN_AUTH" == "true" ]; then
    echo -e "${GREEN}✅ Contratos autorizados correctamente${NC}"
else
    echo -e "${RED}❌ Error en autorizaciones${NC}"
    exit 1
fi
echo ""

# Test 7: Verificar constantes de LearnToEarn
echo -e "${YELLOW}[Test 7/8]${NC} Verificando constantes de LearnToEarn..."
MIN_SCORE=$(cast call $LEARN "MIN_SCORE()(uint256)" --rpc-url scrollSepolia)
LEARNER_POINTS=$(cast call $LEARN "LEARNER_POINTS()(uint256)" --rpc-url scrollSepolia)
EDUCATOR_POINTS=$(cast call $LEARN "EDUCATOR_POINTS()(uint256)" --rpc-url scrollSepolia)

if [ "$MIN_SCORE" == "70" ] && [ "$LEARNER_POINTS" == "100" ] && [ "$EDUCATOR_POINTS" == "50" ]; then
    echo -e "${GREEN}✅ Constantes correctas:${NC}"
    echo -e "   MIN_SCORE: $MIN_SCORE"
    echo -e "   LEARNER_POINTS: $LEARNER_POINTS"
    echo -e "   EDUCATOR_POINTS: $EDUCATOR_POINTS"
else
    echo -e "${RED}❌ Constantes incorrectas${NC}"
    exit 1
fi
echo ""

# Test 8: Verificar reputación inicial
echo -e "${YELLOW}[Test 8/8]${NC} Verificando reputación inicial..."
EDUCATOR_SCORE=$(cast call $REPUTATION "educatorScore(address)(uint256)" $DEPLOYER --rpc-url scrollSepolia)
LEARNER_SCORE=$(cast call $REPUTATION "learnerScore(address)(uint256)" $DEPLOYER --rpc-url scrollSepolia)

echo -e "${GREEN}✅ Reputación inicial:${NC}"
echo -e "   Educator score: $EDUCATOR_SCORE"
echo -e "   Learner score: $LEARNER_SCORE"
echo ""

# Resumen final
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅ Todos los Tests Pasaron! 🎉      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Resumen de Contratos en Scroll Sepolia:${NC}"
echo ""
echo -e "${BLUE}Reputation:${NC}"
echo -e "  https://sepolia.scrollscan.com/address/$REPUTATION"
echo ""
echo -e "${BLUE}EducatorSubscription:${NC}"
echo -e "  https://sepolia.scrollscan.com/address/$SUBSCRIPTION"
echo ""
echo -e "${BLUE}CourseRegistry:${NC}"
echo -e "  https://sepolia.scrollscan.com/address/$COURSE"
echo ""
echo -e "${BLUE}LearnToEarn:${NC}"
echo -e "  https://sepolia.scrollscan.com/address/$LEARN"
echo ""
echo -e "${BLUE}📝 Próximos pasos:${NC}"
echo "  1. Verifica los contratos en Scrollscan"
echo "  2. Configura el frontend: scaffold.config.ts"
echo "  3. Genera ABIs: yarn generate"
echo "  4. Prueba desde el UI: yarn start"
echo ""

