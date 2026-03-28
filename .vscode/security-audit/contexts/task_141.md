# Task 141: Host Header Usage Investigation
getHttpHost() used in: Soap.php:131, SchemaRequestProcessor.php:58, Server.php:70.
Check if Host header reaches email links, SOAP WSDL, response body.
Verify BaseUrlChecker applied before Host header uses.
