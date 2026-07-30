# Deployment Guide

## Complete System Deployment

### Phase 1: Aggregator System (Proxy-Based)

#### 1. Implementation Contract
- **Contract**: `InstaFlashAggregatorBase`
- **Path**: `contracts/aggregator/base/flashloan/main.sol`
- **Purpose**: The actual logic/implementation contract

#### 2. Proxy Admin Contract
- **Contract**: `InstaFlashAggregatorProxyAdmin`
- **Path**: `contracts/proxy/proxyAdmin.sol`
- **Master**: `(Term Management Address)`
- **Purpose**: Manages proxy upgrades and administration

#### 3. Proxy Contract
- **Contract**: `InstaFlashAggregatorProxy`
- **Path**: `contracts/proxy/proxy.sol`
- **Purpose**: Delegatecall proxy that forwards calls to implementation

### Phase 2: Resolver System (Depends on Aggregator)

#### 4. Resolver Contract
- **Contract**: `InstaFlashResolver`
- **Path**: `contracts/resolver/mainnet/main.sol`
- **Purpose**: Read-only contract for route optimization and fee queries
- **Dependency**: Requires aggregator proxy address

## Deployment Order

### Step 1: Deploy Aggregator System
1. Deploy Implementation Contract
2. Deploy Admin Contract (with master address)
3. Deploy Proxy Contract (linking implementation + admin)
4. **Save proxy address** - needed for resolver!
5. Verify all aggregator contracts on Etherscan

### Step 2: Update Resolver Configuration
1. Update `flashloanAggregatorAddr` in `contracts/resolver/mainnet/variables.sol`
2. Replace `0x619Ad2D02dBeE6ebA3CDbDA3F98430410e892882` with actual proxy address
3. Remove TODO comment
4. Recompile contracts

### Step 3: Deploy Resolver
1. Deploy Resolver Contract (with updated aggregator address)
2. Verify resolver contract on Etherscan

## Key Notes
- Users interact with the **proxy address** (never changes)
- Implementation can be upgraded by admin
- Master address has ultimate control over upgrades
- **Critical**: Resolver must be deployed AFTER aggregator with correct proxy address
- Resolver is NOT upgradeable - redeploy if changes needed