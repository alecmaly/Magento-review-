# Context: JWT Security Deep-Dive

## Key Files
- `app/code/Magento/JwtFrameworkAdapter/Model/JwtManager.php` - Core JWT manager, handles JWS/JWE/unsecured
- `app/code/Magento/JwtFrameworkAdapter/Model/UnsecuredJwtManager.php` - Unsecured JWT handling (INVESTIGATE)
- `app/code/Magento/JwtUserToken/Model/Issuer.php` - Token issuance
- `app/code/Magento/JwtUserToken/Model/Reader.php` - Token reading/validation
- `app/code/Magento/JwtUserToken/Model/RevokedValidator.php` - Revocation checking
- `app/code/Magento/JwtUserToken/Model/Revoker.php` - Token revocation
- `app/code/Magento/JwtUserToken/Model/ConfigurableJwtSettingsProvider.php` - Algorithm settings
- `app/code/Magento/JwtUserToken/Model/SecretBasedJwksFactory.php` - JWKS factory

## Supported Algorithms
- Signing: HS256, RS256, ES256, PS256
- Encryption: RSA-OAEP, A128KW, ECDH-ES, PBES2

## Key Questions
1. Algorithm confusion: Can attacker force alg:none via UnsecuredJwtManager?
2. Key management: Where are signing keys stored? Per-installation or shared?
3. SecretBasedJwksFactory: Does it derive JWK from crypt/key?
4. Token revocation completeness: Race window for revoked tokens?
5. JWE+JWS downgrade: Can attacker force signed-only when encrypted expected?
6. kid header injection: Does JwtManager validate kid against known keys?
7. Token expiry: Default expiry? Can client extend?
8. Configurable algorithms: Can admin misconfigure to weak algorithm?
