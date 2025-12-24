#[test_only]
module crowd_walrus::campaign_metadata_tests;

use crowd_walrus::campaign::{Self as campaign, Campaign, CampaignOwnerCap};
use crowd_walrus::crowd_walrus_tests;
use std::string::{Self as string, String};
use std::unit_test::assert_eq;
use sui::clock::Clock;
use sui::event;
use sui::test_scenario::{Self as ts, Scenario};
use sui::vec_map as vec_map;

const ADMIN: address = @0xA;
const OWNER: address = @0xB;
const U64_MAX: u64 = 0xFFFFFFFFFFFFFFFF;

#[test, expected_failure(abort_code = campaign::E_EMPTY_KEY)]
fun test_update_campaign_metadata_empty_key_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b""),
        string::utf8(b"value"),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_EMPTY_VALUE)]
fun test_update_campaign_metadata_empty_value_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b"key"),
        string::utf8(b""),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_KEY_TOO_LONG)]
fun test_update_campaign_metadata_key_too_long_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        make_ascii_string(65),
        string::utf8(b"value"),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_VALUE_TOO_LONG)]
fun test_update_campaign_metadata_value_too_long_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b"key"),
        make_ascii_string(2049),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test, expected_failure(abort_code = campaign::E_TOO_MANY_METADATA_ENTRIES)]
fun test_update_campaign_metadata_too_many_entries_aborts() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    let mut idx = 0;
    while (idx < 100) {
        update_single_metadata(
            &mut scenario,
            &mut campaign_obj,
            &owner_cap,
            &clock,
            unique_metadata_key(idx),
            string::utf8(b"value"),
        );
        idx = idx + 1;
    };

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        unique_metadata_key(100),
        string::utf8(b"value"),
    );

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

#[test]
fun test_update_campaign_metadata_valid_updates_succeed() {
    let mut scenario = crowd_walrus_tests::test_init(ADMIN);

    scenario.next_tx(OWNER);
    let campaign_id = create_test_campaign(&mut scenario);

    scenario.next_tx(OWNER);
    let mut campaign_obj = scenario.take_shared_by_id<Campaign>(campaign_id);
    let owner_cap = scenario.take_from_sender<CampaignOwnerCap>();
    let clock = scenario.take_shared<Clock>();

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b"category"),
        string::utf8(b"technology"),
    );
    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b"twitter"),
        string::utf8(b"@crowdwalrus"),
    );

    let mut idx = 0;
    while (idx < 98) {
        update_single_metadata(
            &mut scenario,
            &mut campaign_obj,
            &owner_cap,
            &clock,
            unique_metadata_key(idx),
            string::utf8(b"value"),
        );
        idx = idx + 1;
    };

    update_single_metadata(
        &mut scenario,
        &mut campaign_obj,
        &owner_cap,
        &clock,
        string::utf8(b"category"),
        string::utf8(b"education"),
    );

    let metadata_view = campaign::metadata(&campaign_obj);
    assert_eq!(vec_map::length(&metadata_view), 100);
    assert_eq!(
        *vec_map::get(&metadata_view, &string::utf8(b"category")),
        string::utf8(b"education"),
    );
    assert_eq!(
        *vec_map::get(&metadata_view, &string::utf8(b"twitter")),
        string::utf8(b"@crowdwalrus"),
    );

    let metadata_events = event::events_by_type<campaign::CampaignMetadataUpdated>();
    assert!(vector::length(&metadata_events) > 0);

    ts::return_shared(campaign_obj);
    scenario.return_to_sender(owner_cap);
    ts::return_shared(clock);
    ts::end(scenario);
}

fun create_test_campaign(scenario: &mut Scenario): sui::object::ID {
    crowd_walrus_tests::create_test_campaign(
        scenario,
        string::utf8(b"Test Campaign"),
        string::utf8(b"Test Description"),
        b"sub",
        vector::empty<String>(),
        vector::empty<String>(),
        1_000_000,
        OWNER,
        0,
        U64_MAX,
    )
}

fun update_single_metadata(
    scenario: &mut Scenario,
    campaign_obj: &mut Campaign,
    owner_cap: &CampaignOwnerCap,
    clock: &Clock,
    key: String,
    value: String,
) {
    let mut keys = vector::empty<String>();
    vector::push_back(&mut keys, key);
    let mut values = vector::empty<String>();
    vector::push_back(&mut values, value);
    campaign::update_campaign_metadata(
        campaign_obj,
        owner_cap,
        keys,
        values,
        clock,
        ts::ctx(scenario),
    );
}

fun unique_metadata_key(index: u64): String {
    if (index < 64) {
        make_ascii_string(index + 1)
    } else {
        let mut bytes = vector::empty<u8>();
        vector::push_back(&mut bytes, 0x62);
        let mut remaining = index - 64 + 1;
        while (remaining > 0) {
            vector::push_back(&mut bytes, 0x61);
            remaining = remaining - 1;
        };
        string::utf8(bytes)
    }
}

fun make_ascii_string(length: u64): String {
    let mut bytes = vector::empty<u8>();
    let mut idx = 0;
    while (idx < length) {
        vector::push_back(&mut bytes, 0x61);
        idx = idx + 1;
    };
    string::utf8(bytes)
}
