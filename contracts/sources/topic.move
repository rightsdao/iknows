
module iknows::topic {

    use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use sui::object_table::{Self as ot, ObjectTable};

    // Resources
    struct Topic has key, store {
        id: UID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        events: vector<TopicEvent>,
        author: address,
        author_name: String,
        created_at: u64,
    }

    struct RichText has store, copy, drop {
        detail: String,
        format: String,
    }

    struct TopicEvent has store, copy, drop {
        event_time: u64,
        description: String,
        created_at: u64,
    }

    struct TopicStore has key, store {
        id: UID,
        title: String,
        topics: ObjectTable<ID, Topic>,
    }

    struct TopicBrief has key, store {
        id: UID,
        topic_id: ID,
        topic_title: String,
        created_at: u64,
    }

    // Events
    struct TopicCreatedEvent has copy, drop {
        topic_id: ID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        // events: vector<TopicEvent>,
        author: address,
        author_name: String,
        created_at: u64,
    }

    struct TopicUpdatedEvent has copy, drop {
        topic_id: ID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        // events: vector<TopicEvent>,
        author_name: String,
        created_at: u64,
    }
    // Errors
    const ENOT_FOUND: u64 = 0;

    // new topic
    public fun new_topic(
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ): Topic {
        let author = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        let content = RichText { detail, format };

        let topic = Topic {
            id: object::new(ctx),
            title,
            content,
            category,
            photos,
            events: vector::empty<TopicEvent>(),
            author,
            author_name,
            created_at,
        };

        emit(TopicCreatedEvent {
            topic_id: object::id(&topic),
            title,
            content: RichText { detail, format },
            category,
            photos,
            // events: vector::empty<TopicEvent>(),
            author,
            author_name,
            created_at,
        });

        topic
    }

    public entry fun create_topic_table(title: String, ctx: &mut TxContext) {
        let author = tx_context::sender(ctx);

        let tb = TopicStore {
            id: object::new(ctx),
            title,
            topics: ot::new<ID, Topic>(ctx),
        };

        transfer::transfer(tb, author);
    }

    public entry fun create_topic(
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ) {
        let author = tx_context::sender(ctx);
        let topic = new_topic(title, detail, format, category, photos, author_name, ctx);

        transfer::transfer(topic, author);
    } 

    public entry fun create_topic_in_store(
        stores: &mut TopicStore,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ) {
        let topic = new_topic(title, detail, format, category, photos, author_name, ctx);

        ot::add(&mut stores.topics, object::id(&topic), topic);
    } 

    public entry fun update_topic(
        topic: &mut Topic,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
    ) {
        let content = RichText { detail, format };
        topic.title = title;
        topic.content = content;
        topic.category = category;
        topic.photos = photos;
        topic.author_name = author_name;

        emit(TopicUpdatedEvent {
            topic_id: object::id(topic),
            title,
            content,
            category,
            photos,
            author_name,
            created_at: topic.created_at
        })
    }

    public entry fun delete_topic(
        topic: Topic
    ) {
        let Topic { id, title: _, content: _, category: _, photos: _, events: _, author: _, author_name: _, created_at: _ } = topic;
        object::delete(id);
    }

    public entry fun delete_topic_in_store(
        stores: &mut TopicStore,
        topic_id: ID,
    ) {
        assert!(ot::contains(&stores.topics, topic_id), ENOT_FOUND);

        let topic = ot::remove(&mut stores.topics, topic_id);
        delete_topic(topic);   
    }

    // Getters
    public fun title(t: &Topic): String {
        t.title
    }

    public fun content(t: &Topic): RichText {
        t.content
    }

    public fun category(t: &Topic): String {
        t.category
    }

    public fun photos(t: &Topic): vector<vector<u8>> {
        t.photos
    }

    public fun events(t: &Topic): vector<TopicEvent> {
        t.events
    }

    public fun author(t: &Topic): address {
        t.author
    }

    public fun author_name(t: &Topic): String {
        t.author_name
    }

    public fun created_at(t: &Topic): u64 {
        t.created_at
    }
}