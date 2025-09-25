#[test_only]
#[allow(unused_const)]
module crowd_walrus::campaign_tests;

use crowd_walrus::campaign::{Campaign, CampaignOwnerCap};
use crowd_walrus::crowd_walrus_tests as crowd_walrus_tests;
use std::string::utf8;
use sui::test_scenario as ts;

const ADMIN: address = @0xA;
const USER1: address = @0xB;
const USER2: address = @0xC;

const TEST_DOMAIN_NAME: vector<u8> = b"test.sui";

#[test]
public fun test_set_is_active() {
    let campaign_owner = USER1;
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(campaign_owner);
    let campaign_id = crowd_walrus_tests::create_test_campaign(
        &mut scenario,
        utf8(b"Test Campaign"),
        utf8(b"A test campaign short description"),
        b"sub",
    );

    {
        scenario.next_tx(campaign_owner);

        let campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();

        assert!(campaign.is_active());

        // clean up
        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
    };

    // Deactivate campaign
    {
        scenario.next_tx(campaign_owner);
        let mut campaign = scenario.take_shared_by_id<Campaign>(campaign_id);
        let campaign_owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
        campaign.set_is_active(&campaign_owner_cap, false);

        assert!(!campaign.is_active());

        // clean up
        ts::return_shared(campaign);
        scenario.return_to_sender(campaign_owner_cap);
    };
    scenario.end();
}
