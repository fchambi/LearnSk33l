#!/bin/bash

# 🚀 Script de Despliegue Automatizado para Scroll Sepolia
# Este script te guía paso a paso en el despliegue de Sk33L

set -e  # Exit on error

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🎓 Sk33L - Scroll Sepolia Deploy   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar que foundry esté instalado
if ! command -v forge &> /dev/null; then
    echo -e "${RED}❌ Foundry no está instalado${NC}"
    echo -e "${YELLOW}Instala Foundry: https://book.getfoundry.sh/getting-started/installation${NC}"
    exit 1
fi

# Verificar que .env existe
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  Archivo .env no encontrado${NC}"
    echo -e "${YELLOW}Creando desde .env.example...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ Archivo .env creado. Por favor configúralo y vuelve a ejecutar este script.${NC}"
    exit 0
fi

# Cargar variables de entorno
source .env

# Verificar configuración de cuenta
if [ -z "$ETH_KEYSTORE_ACCOUNT" ]; then
    echo -e "${YELLOW}⚠️  ETH_KEYSTORE_ACCOUNT no configurado en .env${NC}"
    echo ""
    echo -e "${BLUE}Opciones:${NC}"
    echo -e "1. Generar nueva cuenta: ${GREEN}yarn account:generate${NC}"
    echo -e "2. Importar cuenta existente: ${GREEN}yarn account:import${NC}"
    echo ""
    echo "Después de configurar tu cuenta, edita .env y establece:"
    echo "ETH_KEYSTORE_ACCOUNT=nombre-de-tu-keystore"
    exit 1
fi

# Obtener dirección de la cuenta
echo -e "${BLUE}📋 Verificando configuración...${NC}"
echo ""

# Verificar balance
echo -e "${YELLOW}Verificando balance en Scroll Sepolia...${NC}"
DEPLOYER_ADDRESS=$(cast wallet address --account $ETH_KEYSTORE_ACCOUNT 2>/dev/null || echo "")

if [ -z "$DEPLOYER_ADDRESS" ]; then
    echo -e "${RED}❌ No se pudo obtener la dirección del deployer${NC}"
    echo -e "${YELLOW}Verifica que ETH_KEYSTORE_ACCOUNT='$ETH_KEYSTORE_ACCOUNT' sea correcto${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Deployer: $DEPLOYER_ADDRESS${NC}"

# Verificar balance
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url scrollSepolia 2>/dev/null || echo "0")
BALANCE_ETH=$(cast --to-unit $BALANCE ether 2>/dev/null || echo "0")

echo -e "${BLUE}💰 Balance: $BALANCE_ETH ETH${NC}"
echo ""

# Advertir si balance es bajo
if (( $(echo "$BALANCE_ETH < 0.005" | bc -l) )); then
    echo -e "${RED}⚠️  Balance muy bajo!${NC}"
    echo -e "${YELLOW}Se recomienda al menos 0.01 ETH para el despliegue${NC}"
    echo ""
    echo -e "${BLUE}Pasos para obtener fondos:${NC}"
    echo "1. Obtén Sepolia ETH: https://sepoliafaucet.com/"
    echo "2. Bridge a Scroll Sepolia: https://sepolia.scroll.io/bridge"
    echo ""
    read -p "¿Continuar de todos modos? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Despliegue cancelado${NC}"
        exit 0
    fi
fi

# Compilar contratos
echo -e "${BLUE}🔨 Compilando contratos...${NC}"
forge build
echo -e "${GREEN}✅ Compilación exitosa${NC}"
echo ""

# Preguntar si verificar
echo -e "${BLUE}¿Deseas verificar los contratos automáticamente?${NC}"
echo -e "${YELLOW}(Necesitas SCROLLSCAN_API_KEY en .env)${NC}"
read -p "Verificar? (y/n) " -n 1 -r
echo
VERIFY_FLAG=""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -z "$SCROLLSCAN_API_KEY" ]; then
        echo -e "${RED}❌ SCROLLSCAN_API_KEY no configurado en .env${NC}"
        echo -e "${YELLOW}Obtén tu API key en: https://sepolia.scrollscan.com/myapikey${NC}"
        echo -e "${BLUE}Continuando sin verificación...${NC}"
    else
        VERIFY_FLAG="--verify"
        echo -e "${GREEN}✅ Verificación automática habilitada${NC}"
    fi
fi
echo ""

# Mostrar resumen
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Resumen de Despliegue         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo -e "${BLUE}Red:${NC}           Scroll Sepolia (Chain ID: 534351)"
echo -e "${BLUE}Deployer:${NC}      $DEPLOYER_ADDRESS"
echo -e "${BLUE}Balance:${NC}       $BALANCE_ETH ETH"
echo -e "${BLUE}Verificar:${NC}     $([ -z "$VERIFY_FLAG" ] && echo "No" || echo "Sí")"
echo ""
echo -e "${BLUE}Contratos a desplegar:${NC}"
echo "  1. Reputation"
echo "  2. EducatorSubscription"
echo "  3. CourseRegistry"
echo "  4. LearnToEarn"
echo ""

read -p "¿Iniciar despliegue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Despliegue cancelado${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}🚀 Iniciando despliegue...${NC}"
echo -e "${YELLOW}(Se te pedirá la contraseña de tu keystore)${NC}"
echo ""

# Ejecutar despliegue
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url scrollSepolia \
  --account $ETH_KEYSTORE_ACCOUNT \
  --sender $DEPLOYER_ADDRESS \
  --broadcast \
  --legacy \
  $VERIFY_FLAG

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    ✅ Despliegue Exitoso! 🎉          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}📝 Las direcciones de los contratos se guardaron en:${NC}"
    echo "  - deployments/534351.json"
    echo ""
    echo -e "${BLUE}🔍 Ver en Block Explorer:${NC}"
    echo "  https://sepolia.scrollscan.com/address/$DEPLOYER_ADDRESS"
    echo ""
    echo -e "${BLUE}📚 Próximos pasos:${NC}"
    echo "  1. Verifica los contratos en Scrollscan"
    echo "  2. Genera ABIs para el frontend: ${GREEN}yarn generate${NC}"
    echo "  3. Configura scaffold.config.ts para Scroll Sepolia"
    echo "  4. Prueba los contratos con cast o desde el frontend"
    echo ""
    echo -e "${BLUE}🧪 Comando de prueba rápido:${NC}"
    
    # Leer las direcciones desplegadas si existen
    if [ -f "deployments/534351.json" ]; then
        echo -e "${YELLOW}cast call <REPUTATION_ADDRESS> \"owner()\" --rpc-url scrollSepolia${NC}"
    fi
    echo ""
else
    echo ""
    echo -e "${RED}❌ Error en el despliegue${NC}"
    echo -e "${YELLOW}Revisa los logs arriba para más detalles${NC}"
    exit 1
fi

