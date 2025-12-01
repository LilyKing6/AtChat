#include <iostream>
#include <string>
#include <cstring>
#include "SerialKey.h"
#include "SKU.h"
#include "../Version.h"

void printUsage(const char* programName) {
    std::cout << "AtChat Serial Key Generator\n";
    std::cout << "Usage: " << programName << " <sku> <days> [userinfo]\n\n";
    std::cout << "SKU options:\n";
    std::cout << "  community  - Community Edition (0x0A)\n";
    std::cout << "  pro        - Professional Edition (0xF0)\n";
    std::cout << "  server     - Server Edition (0xFF)\n\n";
    std::cout << "Days: 1-999 (0 for permanent)\n\n";
    std::cout << "Examples:\n";
    std::cout << "  " << programName << " pro 365\n";
    std::cout << "  " << programName << " server 0\n";
    std::cout << "  " << programName << " community 30 user@example.com\n";
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        printUsage(argv[0]);
        return 1;
    }

    std::string skuStr = argv[1];
    int days = std::atoi(argv[2]);
    const char* userInfo = (argc > 3) ? argv[3] : nullptr;

    unsigned char skuId;
    std::string skuName;

    if (skuStr == "community") {
        skuId = SKU_COMMUNITY;
        skuName = SKU_COMMUNITY_STR;
    } else if (skuStr == "pro") {
        skuId = SKU_PRO;
        skuName = SKU_PRO_STR;
    } else if (skuStr == "server") {
        skuId = SKU_SRV;
        skuName = SKU_SRV_STR;
    } else {
        std::cerr << "Error: Invalid SKU '" << skuStr << "'\n";
        printUsage(argv[0]);
        return 1;
    }

    if (days < 0 || days > 999) {
        std::cerr << "Error: Days must be 0-999\n";
        return 1;
    }

    char key[32] = {0};
    int result = SPPGenerateKey(key, sizeof(key), VER_FLAGS, skuId, days, userInfo);

    if (result != 0) {
        std::cerr << "Error: Failed to generate key (code: " << result << ")\n";
        return 1;
    }

    std::cout << "========================================\n";
    std::cout << "AtChat Serial Key Generator\n";
    std::cout << "========================================\n";
    std::cout << "SKU:        " << skuName << "\n";
    std::cout << "Days:       " << (days == 0 ? "Permanent" : std::to_string(days)) << "\n";
    if (userInfo) {
        std::cout << "User Info:  " << userInfo << "\n";
    }
    std::cout << "----------------------------------------\n";
    std::cout << "Serial Key: " << key << "\n";
    std::cout << "========================================\n";

    return 0;
}
