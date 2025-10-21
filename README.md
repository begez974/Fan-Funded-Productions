# 🎬 Fan-Funded Productions

A decentralized crowdfunding platform for creative productions built on Stacks blockchain. Communities can fund music videos, comedy specials, and other creative content while earning profits through tokenized revenue sharing.

## 🚀 Features

- **🎯 Campaign Creation**: Artists create funding campaigns with goals and deadlines
- **💰 Crowdfunding**: Supporters fund campaigns and receive production tokens
- **🎫 Tokenized Ownership**: Backers get tokens representing their share
- **💸 Profit Distribution**: Automated revenue sharing based on token ownership
- **📊 Analytics**: Track campaign progress and funding statistics
- **🔒 Refund Protection**: Automatic refunds for unsuccessful campaigns

## 📋 Contract Functions

### Public Functions

#### Campaign Management
- `create-campaign` - Create new funding campaign
- `fund-campaign` - Fund existing campaign and receive tokens
- `withdraw-funds` - Creator withdraws funds after successful campaign
- `close-campaign` - Close expired campaign
- `emergency-pause` - Pause campaign (creator or contract owner)

#### Revenue Distribution
- `distribute-revenue` - Creator distributes profits to token holders
- `claim-revenue` - Token holders claim their revenue share
- `refund-campaign` - Get refund from unsuccessful campaign

#### Batch Operations
- `batch-fund-campaigns` - Fund multiple campaigns at once

### Read-Only Functions

#### Campaign Info
- `get-campaign` - Get campaign details
- `get-campaign-stats` - Get funding progress and statistics
- `get-campaign-timeline` - Get deadline and timing info
- `get-active-campaigns` - List all active campaigns

#### User Info
- `get-user-campaigns` - Get campaigns created by user
- `get-campaign-backing` - Get user's backing info for campaign
- `get-backer-portfolio` - Get user's investment portfolio

#### Analytics
- `get-contract-stats` - Get platform-wide statistics
- `get-funding-leaderboard` - Top backers for campaign
- `calculate-potential-payout` - Calculate potential earnings

## 🛠️ Usage Examples

### Creating a Campaign
```clarity
(contract-call? .Fan-Funded-Productions create-campaign 
  "Music Video: Summer Nights" 
  "Professional music video production for indie rock band" 
  u50000000 
  u1000)
```

### Funding a Campaign
```clarity
(contract-call? .Fan-Funded-Productions fund-campaign u1 u5000000)
```

### Claiming Revenue
```clarity
(contract-call? .Fan-Funded-Productions claim-revenue u1)
```

### Distributing Profits
```clarity
(contract-call? .Fan-Funded-Productions distribute-revenue u1 u25000000)
```

## 🏗️ Development

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Setup
```bash
clarinet check
clarinet test
```

### Testing
```bash
clarinet test --coverage
```

## 📈 Token Economics

- **Token Symbol**: FFP (Fan-Funded Productions)
- **Decimals**: 6
- **Distribution**: 1:1 ratio with STX funding amount
- **Revenue Share**: Proportional to token ownership
- **Utility**: Governance and profit sharing rights

## 🔐 Security Features

- Campaign deadline enforcement
- Refund protection for failed campaigns
- Creator-only withdrawal controls
- Emergency pause functionality
- Claiming protection against double-spending

## 📊 Campaign Lifecycle

1. **📝 Creation** - Artist creates campaign with funding goal
2. **💰 Funding** - Community backs project, receives tokens
3. **🎯 Goal Check** - Campaign succeeds if goal reached by deadline
4. **🎬 Production** - Creator withdraws funds and produces content
5. **💸 Revenue** - Profits distributed to token holders
6. **🔄 Claims** - Token holders claim their earnings

## 🎯 Use Cases

- **🎵 Music Videos**: Fund professional music video production
- **🎭 Comedy Specials**: Crowdfund stand-up comedy recordings
- **🎨 Art Projects**: Support creative digital content
- **📺 Web Series**: Finance episodic content creation
- **🎪 Live Events**: Fund performances and recordings

## 🤝 Contributing

This project uses Clarinet for smart contract development. Ensure all changes pass `clarinet check` before submitting.

## 📄 License

MIT License - Feel free to fork and create your own creative funding platforms!

---

*Building the future of decentralized creative funding* 🌟
