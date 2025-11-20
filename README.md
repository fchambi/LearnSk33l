# 🎓 Sk33L — Web3 Learn-to-Earn Education Platform

**A decentralized education platform where students subscribe to educators and earn onchain reputation by completing courses.  
Built with Scaffold-ETH 2, Foundry, Wagmi, Viem and Next.js.**

---

## 🔗 Project Links

- 🌐 **Website / Demo:** https://v0-skool-3.vercel.app/ 

### 🧩 Smart Contracts on Scroll (All Verified ✔)

- **Reputation.sol** — `0x1aa7d8045D18e3ed70103f32294a14E839D7Ce01`  
  https://repo.sourcify.dev/534351/0x1aa7d8045D18e3ed70103f32294a14E839D7Ce01

- **EducatorSubscription.sol** — `0x3E42fB1C4D04916e86b741049df219EB3D71ca82`  
  https://repo.sourcify.dev/534351/0x3E42fB1C4D04916e86b741049df219EB3D71ca82

- **CourseRegistry.sol** — `0xf7596AEAc4515350B100048Edc4F6FeB02F604Df`  
  https://repo.sourcify.dev/534351/0xf7596AEAc4515350B100048Edc4F6FeB02F604Df

- **LearnToEarn.sol** — `0x75aaAad403b206db02B8bD0ea8E357D238Ae48f3`  
  https://repo.sourcify.dev/534351/0x75aaAad403b206db02B8bD0ea8E357D238Ae48f3
---

## 🚀 What Is Sk33L?

Sk33L is a Web3 education platform where educators create courses and students subscribe on-chain to access the content.  
Students earn **onchain reputation** by completing courses, while educators gain reputation from subscribers and student completions.  
The goal is to build a transparent, decentralized and merit–driven learning ecosystem powered by blockchain.

---

## 🌟 Key Features

- **On-Chain Subscriptions:** Monthly subscription model similar to Skool  
- **Course Registry:** Courses stored with decentralized IPFS metadata  
- **Reputation System:** Onchain scores for both educators and learners  
- **Learn-to-Earn:** Reputation rewards for successful course completion  
- **2% Platform Fee:** 98% goes directly to the educator  
- **Minimal Smart Contracts:** Simple, audit-friendly and easy to extend  

---

## 🧱 Core Smart Contracts

- **Reputation.sol** — Tracks onchain scores for educators and learners  
- **EducatorSubscription.sol** — Manages subscription plans and payments  
- **CourseRegistry.sol** — Registers and manages course metadata  
- **LearnToEarn.sol** — Validates completions and distributes reputation  

**Key configuration values:**
- Minimum score: 70%  
- Learner reward: 100 points  
- Educator reward: 50 points  
- Subscription duration: 30 days per month  

---

## 🔄 User Flow Overview

1. Educator sets a subscription price and publishes courses  
2. Student subscribes on-chain  
3. Student accesses educator content with active subscription  
4. Student completes a course with minimum score  
5. Both educator and learner earn onchain reputation  

---

## ⚙️ Tech Stack

- Scaffold-ETH 2  
- Foundry  
- Next.js + TypeScript  
- Wagmi + Viem  
- RainbowKit  
- IPFS  

---

## 🎨 Frontend Features

### Educator Dashboard (`/educator`)
- Set monthly subscription price
- Create courses with IPFS metadata URIs
- Activate/deactivate courses
- View educator reputation in real-time

### Learner Dashboard (`/learner`)
- Browse available educators and their prices
- Subscribe with ETH payment (1-12 months)
- View courses by educator
- Complete courses with score validation (minimum 70)
- View learner reputation in real-time

## 📚 Project Structure

```
learnskool3/
├── packages/
│   ├── foundry/           # Smart contracts
│   │   ├── contracts/     # Solidity contracts
│   │   ├── script/        # Deployment scripts
│   │   ├── test/          # Contract tests
│   │   └── seed-data.sh   # Script to seed test data
│   └── nextjs/            # Frontend application
│       ├── app/           # Next.js pages
│       │   ├── educator/  # Educator dashboard
│       │   └── learner/   # Learner dashboard
│       └── components/    # React components
└── setup-demo.sh          # Automated setup script
```
