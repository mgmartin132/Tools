# Disable ciphers that are considered 'weak'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_RC4_128_MD5'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_RC4_128_SHA'

# Disable ciphers that use no encryption
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_NULL_SHA256'
Disable-TlsCipherSuite -Name 'TLS_RSA_WITH_NULL_SHA'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_NULL_SHA384'
Disable-TlsCipherSuite -Name 'TLS_PSK_WITH_NULL_SHA256'