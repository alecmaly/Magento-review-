# Task 088 Context: Weak PRNG in Security Contexts

## Background
Framework Math/Random uses random_int() (CSPRNG) correctly. But many places bypass it.

## Known Weak PRNG Usage
### Security-relevant (investigate):
1. PageCache Version.php:59 - md5(rand() . time()) for private_content_version cookie [FINDING L-006]
2. MessageQueue Rpc/Publisher.php:105 - rand() for correlation_id
3. MessageQueue Bulk/Rpc/Publisher.php:100 - same
4. Lock/Backend/Cache.php:154 - uniqid in lock signing
5. RemoteSynchronizedCache.php:465 - same uniqid pattern

### Non-security (dismissed):
- Template HTML ID generation, temp file names, CMS duplicate identifiers
- Catalog Random product ordering, theme preview names
- Cache eviction probability, report IDs

## Questions
- Can correlation_id prediction enable message hijacking?
- Can cache lock signing with uniqid() enable lock bypass?
