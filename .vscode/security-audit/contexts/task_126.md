# Task 126: Redis Session/Cache Auth and Deser Exposure

## Key Files
- setup/src/Magento/Setup/Model/ConfigOptionsList/Session.php - Redis password defaults empty
- lib/internal/Magento/Framework/Session/SaveHandler/Redis.php - wraps Cm\RedisSession
- lib/internal/Magento/Framework/Session/SessionManager.php:260 - session_set_save_handler()

## Critical: Session vs Cache Deserialization
- Cache: Serialize.php with allowed_classes=false - NO object instantiation
- Session: PHP native session handler - NO allowed_classes - FULL object instantiation

## Gadget Candidates
- Framework/DB/Adapter/Pdo/Mysql::__destruct() (line 4276)
- Framework/Archive/Helper/File::__destruct() (line 75)
- CatalogRule/Model/Indexer/IndexerTableSwapper::__destruct() (line 166) - DROP tables
- Deploy/Process/Queue::__destruct() (line 454)

## Investigate
1. Does Cm\RedisSession compress/encode preventing raw PHP unserialize?
2. Default Redis bind address?
3. Can phpggc generate Magento chains?
