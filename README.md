# CrowdWalrus Smart Contracts

CrowdWalrus delivers a non-custodial crowdfunding platform on Sui with real-time USD valuation, profile-driven loyalty, and badge rewards. Phase 2 focuses on transparent donations, configurable platform fees, and analytics-friendly events.

## Phase 2 Highlights
- Multi-token donations: accept any Coin<T> the platform enables in the shared `TokenRegistry`.
- On-chain USD pricing: each donation is valued in micro-USD via Pyth price feeds with staleness and donor slippage safeguards.
- Typed campaign goals and payout policies: platform and recipient addresses plus basis points are embedded in every campaign and locked after the first donation.
- Live aggregates: `CampaignStats` tracks total USD and per-coin totals while profiles aggregate lifetime donor activity.
- Soulbound badges: five badge levels celebrate donor progress with wallet-renderable Display metadata.
- Platform fee presets: admins seed named platform policies that campaign creators can adopt without re-auditing math.

## Key User Flows
**Campaign owners**
- Call `crowd_walrus::create_campaign` with dates, funding_goal_usd_micro, and optional platform policy preset name.
- If no profile exists, the system auto-creates one, links a new `CampaignStats` object, and emits `ProfileCreated` and `CampaignStatsCreated` events.

**First-time donors**
- Submit a PTB that refreshes the relevant Pyth price feed and calls `donations::donate_and_award_first_time<T>`.
- Contracts create and transfer a profile, value the donation in USD, split funds per the campaign policy, lock campaign parameters, update stats, and mint the first badge level if thresholds are met.

**Repeat donors**
- Reuse their owned `Profile` object with `donations::donate_and_award<T>` to compound totals and unlock higher badges; no new objects are created.

**Platform admins**
- Manage accepted tokens, fee presets, and badge configuration using the AdminCap provided at package publish.
- Events surface every change (`TokenAdded`, `PolicyUpdated`, `BadgeConfigUpdated`) so downstream systems stay in sync.

## Admin Controls & Guardrails
- `token_registry.move`: define coin symbol, name, decimals, enabled flag, Pyth feed id, and max allowable staleness (ms).
- `platform_policy.move`: curate named platform fee presets (including the seeded "standard" default) and enforce that critical parameters lock after first donation.
- `badge_rewards.move`: configure donation amount and count thresholds plus Walrus-hosted image URIs; register wallet Display metadata once per deployment.
- All arithmetic is checked, USD rounding floors in favor of recipients, and the remainder of splits always routes to the campaign recipient.

## Data & Analytics
- `DonationReceived` events capture canonical coin type, human-readable symbol, raw amounts, USD valuations, fee split, and timestamp—everything needed for dashboards without recomputing math. See `docs/phase2/EVENT_SCHEMAS.md` for full field definitions.
- Profiles and campaigns expose read-only getters for cumulative USD, donation counts, and per-coin totals, eliminating the need to replay history.
- Parameter lock events (`CampaignParametersLocked`) provide an indexer-friendly milestone when fundraising terms go live.

## Modules at a Glance
- `crowd_walrus.move`: package init, shared object bootstrap, campaign creation entry.
- `campaign.move`: campaign struct, payout policy validation, metadata management, parameter locking.
- `donations.move`: donation flows, slippage enforcement, price oracle integration, profile updates, badge minting.
- `price_oracle.move`: USD valuation helper with feed validation and staleness checks.
- `campaign_stats.move`: shared aggregates plus per-coin dynamic fields.
- `profiles.move`: registry, owned profile object, metadata updates, auto-create helper.
- `badge_rewards.move`: badge config, DonorBadge minting, Display registration.
- `platform_policy.move`: named platform fee presets and global defaults.
- `token_registry.move`: accepted token metadata and freshness policy.

## Quick Start
```bash
# Clone and build
git clone <repository-url>
cd crowd-walrus-contracts
sui move build

# Run tests
sui move test

# (Optional) deploy to testnet
sui client switch --env testnet
sui client publish --gas-budget 500000000
```

After publish, follow the [post-deployment checklist](#post-deployment-checklist) to wire SuiNS, tokens, badges, and platform policies.

## Working With The Contracts
- Build and test locally with `sui move build` and `sui move test`.
- Developer-focused PTB recipes, admin runbooks, and price feed guidance live in `docs/phase2/PHASE_2_DEV_DOCUMENT.md` and `docs/phase2/POST_DEPLOYMENT_CONFIG.md`.
- Deployment outputs include the shared object IDs for TokenRegistry, ProfilesRegistry, PlatformPolicy, BadgeConfig, and the AdminCap—record them for frontend and ops tooling.

## Post-Deployment Checklist
- Capture the shared object IDs emitted at publish (CrowdWalrus, TokenRegistry, ProfilesRegistry, PolicyRegistry, BadgeConfig, SuiNSManager) and store them for frontend/indexer configs.
- Transfer the `AdminCap` to the operations wallet, then configure platform policy presets (update the seeded "standard" entry and add/enable others as needed).
- Wire SuiNS subdomains by calling `crowd_walrus::set_suins_nft` with the production `SuinsRegistration` NFT.
- Populate `TokenRegistry` entries for every supported Coin<T> with symbol/name/decimals, Pyth feed IDs, default staleness, then enable each token.
- Seed badge thresholds and Walrus image URIs through `crowd_walrus::update_badge_config` so donor milestones mint correctly.
- Follow the full operational checklist in `docs/phase2/POST_DEPLOYMENT_CONFIG.md` for detailed command sequences and validation steps.

## Additional Resources
- Product requirements: `docs/phase2/PHASE_2_PRODUCT_DOCUMENT.md`
- Post-deployment configuration playbook: `docs/phase2/POST_DEPLOYMENT_CONFIG.md`
- Badge display setup: `docs/phase2/PUBLISHER_DISPLAY_SETUP.md`
