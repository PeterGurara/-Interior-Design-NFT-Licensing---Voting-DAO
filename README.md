A revolutionary Clarity smart contract that empowers interior designers to tokenize, license, and monetize their creative works while building a decentralized community around design trends and innovation.

## 🚀 Features

### 🎨 NFT Design Packs
- **Mint Design NFTs**: Transform your 3D models, layouts, and color palettes into tradeable NFTs
- **Metadata Storage**: Store design titles, types, and IPFS hashes on-chain
- **Creator Attribution**: Permanent creator tracking with royalty systems

### 🏪 Marketplace & Licensing
- **Design Marketplace**: List and sell your design NFTs with customizable pricing
- **Flexible Licensing**: License designs for commercial or personal use with duration controls
- **Smart Royalties**: Automatic royalty distribution to creators (70%), decorators (15%), vendors (10%), and DAO (5%)

### 🗳️ DAO Governance
- **Proposal System**: Create and vote on design trends, contests, and platform improvements
- **Contest Hosting**: Submit designs to community contests with voting mechanisms
- **Treasury Management**: Collective fund management for platform development

### ⭐ Rating & Feedback
- **Design Ratings**: Community-driven 1-5 star rating system
- **Quality Metrics**: Aggregate ratings help identify trending designs
- **Creator Reputation**: Build reputation through consistent quality work

### 💖 Favorite Designs
- **Personal Collections**: Curate favorite designs for easy access and inspiration
- **User Personalization**: Bookmark designs to build personal design portfolios
- **Community Engagement**: Enhance discoverability and user interaction

### 🔥 NFT Burning Mechanism
- **Creator-Controlled Burning**: Original creators can permanently remove their NFTs from circulation
- **Clean State Management**: Automatically clears all associated metadata, licenses, listings, auctions, and lending records
- **Digital Rights Management**: Provides creators ultimate control over their intellectual property lifecycle

### 💰 NFT Lending System
- **Collateral-Based Lending**: Lend NFTs with STX collateral for temporary access
- **Flexible Terms**: Set custom lending fees and duration periods
- **Secure Returns**: Automatic NFT return or collateral claim on expiry
- **Risk Management**: Built-in protections for lenders and borrowers

## 📋 Contract Functions

### Core NFT Functions
```clarity
(mint-design-nft title design-type ipfs-hash royalty-rate recipient)
(get-design-metadata token-id)
(get-owner token-id)
```

### Marketplace Functions
```clarity
(list-for-sale token-id price license-terms)
(purchase-design token-id)
(license-design token-id license-fee commercial-use duration-blocks)
```

### DAO Functions
```clarity
(create-dao-proposal title description proposal-type voting-duration)
(vote-on-proposal proposal-id vote-for)
(get-dao-proposal proposal-id)
```

### Rating System
```clarity
(rate-design token-id rating)
(get-design-rating token-id)
```

### Favorite System
```clarity
(add-to-favorites token-id)
(remove-from-favorites token-id)
(is-design-favorited user token-id)
```

### Burning System
```clarity
(burn-design-nft token-id)
```

### Lending System
```clarity
(lend-nft token-id collateral-amount lending-fee duration-blocks)
(borrow-nft token-id)
(return-nft token-id)
(claim-collateral token-id)
(get-lending-info token-id)
```

### Contest System
```clarity
(submit-to-contest contest-id submission-hash)
(vote-contest-submission submission-id)
```

## 🛠️ Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet configured
- Basic understanding of Clarity smart contracts

### Installation
1. Clone this repository
2. Navigate to the project directory
3. Run `clarinet check` to validate the contract
4. Deploy using `clarinet deploy`

### Usage Examples

#### 🎨 Minting a Design NFT
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO mint-design-nft 
  "Modern Kitchen Design" 
  "kitchen" 
  "QmXYZ123..." 
  u10 
  'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

#### 🏪 Listing for Sale
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO list-for-sale u1 u1000000 true)
```

#### 📜 Licensing a Design
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO license-design u1 u500000 true u2016)
```

#### 🗳️ Creating a DAO Proposal
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO create-dao-proposal
  "Q4 Design Contest Theme"
  "Vote on the theme for our quarterly design contest"
  "contest"
  u1440)
```

#### 💖 Favoriting a Design
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO add-to-favorites u1)
```

#### 💰 Lending an NFT
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO lend-nft u1 u1000000 u50000 u1440)
```

#### 🔄 Borrowing an NFT
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO borrow-nft u1)
```

#### ↩️ Returning an NFT
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO return-nft u1)
```

#### 🔥 Burning a Design NFT
```clarity
(contract-call? .Interior-Design-NFT-Licensing---Voting-DAO burn-design-nft u1)
```

## 💰 Tokenomics

### Royalty Distribution
- **70%** → Original Creator
- **15%** → Decorator/Collaborator
- **10%** → Vendor/Platform Partner  
- **5%** → DAO Treasury

### Revenue Streams
- 💸 Design NFT sales
- 📄 Licensing fees
- 🏆 Contest entry fees
- 🤝 Marketplace transaction fees
- 💰 NFT lending fees
- 🔥 NFT burning for permanent removal

## 🏗️ Architecture

The contract implements several key data structures:
- **design-metadata**: Core NFT information and creator details
- **marketplace-listings**: Active sale listings with pricing
- **design-licenses**: Licensing agreements and terms
- **dao-proposals**: Governance proposals and voting data
- **royalty-splits**: Revenue distribution configurations
- **user-favorites**: User favorite design mappings
- **nft-lendings**: NFT lending agreements with collateral and terms
- **burning-mechanism**: Creator-controlled NFT destruction with state cleanup

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

Check contract syntax:
```bash
clarinet check
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🌟 Roadmap

- [x] 💰 NFT Lending System
- [x] 🔥 NFT Burning Mechanism
- [ ] 📱 Mobile app integration
- [ ] 🔄 Cross-chain compatibility
- [ ] 🤖 AI-powered design recommendations
- [ ] 🌐 IPFS integration improvements
- [ ] 📊 Advanced analytics dashboard

## ⚠️ Security Considerations

- All financial transactions use STX transfers with proper validation
- Ownership checks prevent unauthorized actions
- Voting mechanisms include anti-spam protections
- License expiry enforced through block height validation
- NFT burning requires creator authorization and cleans all associated state

---

Built with ❤️ for the interior design community on Stacks blockchain
