# 🎓 Sk33L - Web3 Education Platform

**A decentralized Learn-to-Earn education platform built on Scaffold-ETH 2**

Sk33L is a Web3 education platform where educators create communities and publish courses, while students subscribe to educators and earn onchain reputation by completing courses.

## 🌟 Key Features

- 💰 **Educator Subscriptions**: Monthly subscription model (similar to Skool) where students subscribe to educators
- 📚 **Course Management**: Educators can create and manage courses with IPFS metadata
- 🏆 **Reputation System**: Both educators and learners earn reputation points through engagement
- 🎁 **Learn-to-Earn**: Students earn onchain rewards by completing courses (requires active subscription)
- 💸 **Platform Fee**: 2% platform fee with 98% going directly to educators

## 🏗️ Architecture

Sk33L consists of four main smart contracts:

### 1. **Reputation.sol**
- Tracks reputation scores for educators and learners
- Uses access control to allow only authorized contracts to modify scores
- Educators gain reputation from subscriptions and course completions
- Learners gain reputation from completing courses

### 2. **EducatorSubscription.sol**
- Manages monthly subscriptions to educators
- Handles payment split: 2% platform fee, 98% to educator
- Supports multi-month subscriptions with automatic expiry extension
- Educators can pause/resume their subscription plans

### 3. **CourseRegistry.sol**
- Registry for courses created by educators
- Stores course metadata (IPFS URIs)
- Educators can activate/deactivate their courses

### 4. **LearnToEarn.sol**
- Validates course completions
- Requires active subscription to complete courses
- Enforces minimum score requirement (70%)
- Distributes reputation rewards (100 points to learner, 50 to educator)
- Prevents duplicate completions

## 🔄 User Flow

1. **Educator Setup**: Educator sets monthly subscription price and creates courses
2. **Student Subscribe**: Student subscribes to educator (pays in ETH)
3. **Access Content**: Student can access course content (frontend validation)
4. **Complete Course**: Student completes course with score ≥ 70% and claims onchain rewards
5. **Earn Reputation**: Both student and educator gain reputation points

⚙️ Built using NextJS, RainbowKit, Foundry, Wagmi, Viem, and Typescript.

- ✅ **Contract Hot Reload**: Your frontend auto-adapts to your smart contract as you edit it.
- 🪝 **[Custom hooks](https://docs.scaffoldeth.io/hooks/)**: Collection of React hooks wrapper around [wagmi](https://wagmi.sh/) to simplify interactions with smart contracts with typescript autocompletion.
- 🧱 [**Components**](https://docs.scaffoldeth.io/components/): Collection of common web3 components to quickly build your frontend.
- 🔥 **Burner Wallet & Local Faucet**: Quickly test your application with a burner wallet and local faucet.
- 🔐 **Integration with Wallet Providers**: Connect to different wallet providers and interact with the Ethereum network.

## 📋 Smart Contract Details

| Contract | Description | Key Functions |
|----------|-------------|---------------|
| **Reputation** | Reputation tracking | `increaseEducatorScore`, `increaseLearnerScore`, `setAuthorized` |
| **EducatorSubscription** | Subscription management | `setMonthlyPrice`, `subscribe`, `isSubscribed`, `pausePlan` |
| **CourseRegistry** | Course registry | `createCourse`, `setCourseActive`, `getCourse` |
| **LearnToEarn** | Course completion & rewards | `completeCourse`, `hasCompletedCourse` |

### Constants & Configuration

- **Platform Fee**: 2% (200 basis points)
- **Minimum Completion Score**: 70
- **Learner Reward**: 100 reputation points
- **Educator Reward**: 50 reputation points per course completion
- **Subscription Duration**: 30 days per month

## Requirements

Before you begin, you need to install the following tools:

- [Node (>= v20.18.3)](https://nodejs.org/en/download/)
- Yarn ([v1](https://classic.yarnpkg.com/en/docs/install/) or [v2+](https://yarnpkg.com/getting-started/install))
- [Git](https://git-scm.com/downloads)

## 🚀 Quickstart

To get started with Sk33L, follow the steps below:

### 1. Install dependencies

```bash
yarn install
```

### 2. Run tests

Test all smart contracts to ensure everything works:

```bash
yarn foundry:test
```

Run specific test files:

```bash
forge test --match-contract ReputationTest -vvv
forge test --match-contract EducatorSubscriptionTest -vvv
forge test --match-contract CourseRegistryTest -vvv
forge test --match-contract LearnToEarnTest -vvv
```

### 3. Start local blockchain

In a first terminal, run a local Ethereum network:

```bash
yarn chain
```

This command starts a local Ethereum network using Foundry. The network runs on your local machine and can be used for testing and development.

### 4. Deploy contracts

On a second terminal, deploy the Sk33L smart contracts:

```bash
yarn deploy
```

This deploys all four contracts in the correct order:
1. Reputation
2. EducatorSubscription (with Reputation address)
3. CourseRegistry
4. LearnToEarn (with all contract addresses)

The deployment script also sets up the proper authorizations in the Reputation contract.

### 5. Start the frontend

On a third terminal, start your NextJS app:

```bash
yarn start
```

Visit your app on: `http://localhost:3000`. You can interact with your smart contracts using the `Debug Contracts` page at `http://localhost:3000/debug`.

## 🧪 Testing

The project includes comprehensive test coverage:

- **Reputation.t.sol**: Tests authorization and score management
- **EducatorSubscription.t.sol**: Tests subscriptions, payment splits, and expiry logic
- **CourseRegistry.t.sol**: Tests course creation and management
- **LearnToEarn.t.sol**: Integration tests for the complete learn-to-earn flow

Run all tests:
```bash
yarn foundry:test
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

Run tests with detailed traces:
```bash
forge test -vvv
```

## 🛠️ Development

- **Smart Contracts**: `packages/foundry/contracts/`
  - `Reputation.sol`
  - `EducatorSubscription.sol`
  - `CourseRegistry.sol`
  - `LearnToEarn.sol`

- **Tests**: `packages/foundry/test/`
  - `Reputation.t.sol`
  - `EducatorSubscription.t.sol`
  - `CourseRegistry.t.sol`
  - `LearnToEarn.t.sol`

- **Deployment Scripts**: `packages/foundry/script/`
  - `Deploy.s.sol` (main orchestrator)
  - `DeployReputation.s.sol`
  - `DeployEducatorSubscription.s.sol`
  - `DeployCourseRegistry.s.sol`
  - `DeployLearnToEarn.s.sol`

- **Frontend**: `packages/nextjs/app/`
  - Edit your homepage at `packages/nextjs/app/page.tsx`
  - For routing and pages/layouts, check the [Next.js documentation](https://nextjs.org/docs/app/building-your-application/routing)

- **Configuration**: `packages/nextjs/scaffold.config.ts`
  - Configure target networks, burner wallet, and more


## 📖 How to Use Sk33L

### For Educators

1. **Set Your Price**:
   ```javascript
   // Call setMonthlyPrice on EducatorSubscription contract
   await educatorSubscription.setMonthlyPrice(parseEther("0.1")); // 0.1 ETH/month
   ```

2. **Create a Course**:
   ```javascript
   // Call createCourse on CourseRegistry contract
   await courseRegistry.createCourse("ipfs://QmYourCourseMetadata...");
   ```

3. **Manage Your Plan**:
   ```javascript
   // Pause your subscription plan
   await educatorSubscription.pausePlan();
   
   // Resume your subscription plan
   await educatorSubscription.resumePlan();
   ```

### For Students

1. **Subscribe to an Educator**:
   ```javascript
   // Subscribe for 3 months
   await educatorSubscription.subscribe(educatorAddress, 3, { 
     value: parseEther("0.3") // 3 months × 0.1 ETH
   });
   ```

2. **Complete a Course**:
   ```javascript
   // Complete course with your score (must be ≥ 70)
   await learnToEarn.completeCourse(courseId, 85);
   ```

3. **Check Your Reputation**:
   ```javascript
   const myReputation = await reputation.learnerScore(myAddress);
   ```

## 🔍 Using the Debug Contracts Page

Visit `http://localhost:3000/debug` to interact with the contracts through a UI:

1. **Reputation**: View and manage reputation scores
2. **EducatorSubscription**: Set prices, subscribe, check subscriptions
3. **CourseRegistry**: Create and manage courses
4. **LearnToEarn**: Complete courses and earn rewards

## 📝 Contract Interactions with Scaffold-ETH Hooks

### Reading Contract Data

```typescript
import { useScaffoldReadContract } from "~~/hooks/scaffold-eth";

// Check if subscribed
const { data: isSubscribed } = useScaffoldReadContract({
  contractName: "EducatorSubscription",
  functionName: "isSubscribed",
  args: [studentAddress, educatorAddress],
});

// Get learner reputation
const { data: reputation } = useScaffoldReadContract({
  contractName: "Reputation",
  functionName: "learnerScore",
  args: [learnerAddress],
});
```

### Writing to Contracts

```typescript
import { useScaffoldWriteContract } from "~~/hooks/scaffold-eth";

// Subscribe to educator
const { writeContractAsync } = useScaffoldWriteContract("EducatorSubscription");

await writeContractAsync({
  functionName: "subscribe",
  args: [educatorAddress, 1],
  value: parseEther("0.1"),
});

// Complete a course
const { writeContractAsync: completeAsync } = useScaffoldWriteContract("LearnToEarn");

await completeAsync({
  functionName: "completeCourse",
  args: [courseId, score],
});
```

### Reading Events

```typescript
import { useScaffoldEventHistory } from "~~/hooks/scaffold-eth";

// Get course completion events
const { data: completions } = useScaffoldEventHistory({
  contractName: "LearnToEarn",
  eventName: "CourseCompleted",
  watch: true,
});
```

## 🌐 Deploying to Live Networks

1. Generate or import a deployer account:
   ```bash
   yarn generate  # Generate new account
   # or
   yarn account:import  # Import existing private key
   ```

2. Deploy to a live network:
   ```bash
   yarn deploy --network sepolia
   # or
   yarn deploy --network optimism
   # or any network configured in foundry.toml
   ```

3. Verify contracts on Etherscan:
   ```bash
   yarn verify --network sepolia
   ```

## 📚 Documentation

- [Scaffold-ETH 2 Documentation](https://docs.scaffoldeth.io)
- [Foundry Book](https://book.getfoundry.sh/)
- [Next.js Documentation](https://nextjs.org/docs)
- [RainbowKit Documentation](https://www.rainbowkit.com/docs/introduction)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.
Please see [CONTRIBUTING.MD](https://github.com/scaffold-eth/scaffold-eth-2/blob/main/CONTRIBUTING.md) for more information and guidelines for contributing to Scaffold-ETH 2.