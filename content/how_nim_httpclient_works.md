---
title: "How Nim's httpclient works"
date: 2020-06-10T10:40:49+08:00
draft: true
---

In this article, we'll analyze how the Nim HTTP Client module performs a HTTP GET request.

Let's start top down. A client makes a HTTP request like this:
```nim
var client = newHttpClient()
echo client.getContent("https://nim-lang.org")
```

In other words, a HTTP Client object is made, then the getContent() function is called on this object.

## What's in a HTTP Client? 

This analysis is only for the simpler blocking HTTP requests, not the async HTTP requests. That said, the differences are not that major.

In Nim, a HTTP client is comprised of a few parts:
  1. Every HTTP Client is generic over a *Socket Type*, which describes the type of socket used. This is so that users can plug in their own sockets if the default socket isn't good enough.
  1. A boolean describing whether or not the HTTP client is in a connected state.
  1. A current URL, which the client is connected to.
  1. HTTP headers.
  1. Max number of redirects before the client stops.
  1. User agent. By default, this is *Nim httpclient/1.2.0*, or whatever Nim version you're running.
  1. Timeout parameter for requests. If the connection takes longer than this timeout, the request is cancelled.
  1. Proxy for HTTP requests (if any). Explained below.
  1. A callback function, called *onProgressChanged*, which signals the client of what to do when the request makes some more progress. This can be used to create a progress bar, for instance.
  1. various helpers for the callback, including *total Progress*, *current progress*, *last second progress*, *time of last progress report*.
  1. An SSL Context (if using SSL). Explained below.
  1. A *stream* which holds the request body. Explained below. In an async setting, this would be a FutureStream.

This can be found in `lib/pure/httpclient.nim`.

### Sockets

A Nim socket is an abstraction over the various native OS sockets that the major vendors (Windows, MacOS, GNU/Linux) use. 
As the focus of this post is on a HTTP Client, I won't go too much into detail about a socket. For the interested but uninitiated, you should read up on Berkeley sockets and follow Beej's guide to network programming.

For our purposes, we can think of a socket as a big buffer of bytes. There is an integer describing where the HTTP Client has read in the buffer, and another integer describing the size of the buffer.

By default, the buffer size is 4000 bytes.

This can be found in `lib/pure/net.nim`.

### Streams

WIP.

## SSL support

SSL (secure sockets layer), nowadays renamed as TLS (transport layer security), is what makes the **s** in http**s**. A modern HTTP client must have SSL support in order to interface with most websites. Nim makes use of the OpenSSL library to perform SSL encoding and decoding. That said, SSL support in Nim is not turned on by default, and must be explicitly requested by compiling the program with `nim c -d:ssl`. 

### SSL Context object

A SSLContext object consists of three parts
1. An SslCtx object.
1. A HashSet of referenced data
1. Two functions
  a. a serverGetPSKFunc
  b. a clientGetPSKFunc

What is SslCtx? Well, it turns out that Nim's SSL support is dependent on the OpenSSL Library. Thus, SslCtx can be found in the `wrappers/openssl.nim` file, in which we see that it is an alias for openSSL's SslPtr, which is a C pointer to a SSL object. That SSL object is an openSSL internal, the documentation of which can be found [on their man page](https://www.openssl.org/docs/manmaster/man7/ssl.html).

This can be found in `lib/pure/net.nim`.

### SSL library initialization

In Nim, SSL support is done at compile time, by invoking the `-d:ssl` flag. There are many things that this flag changes, but at program init time, these functions are run:
```nim
CRYPTO_malloc_init()
doAssert SslLibraryInit() == 1
SSL_load_error_strings()
ERR_load_BIO_strings()
OpenSSL_add_all_algorithms()
```

These functions are part of the OpenSSL library, and they are global objects that need to be initialized before any SSL connections can be made.

### SSL Certificates

SSL certificates are a complex beast, so here's my two cents, which is mostly inaccurate but somewhat accurate:

When you visit "https://nim-lang.org", the web server will send back a certificate file. This certificate file basically lets the Nim web server to say "I am indeed the server that serves nim-lang.org". 

How do you, the HTTP client, know that this claim is more than just a pile of hot air? The answer is that the nim-lang certificate is **signed** by another website. As of Jun 10 2020, it is signed by sni.cloudflaressl.com. What gives sni.cloudflaressl.com the right to sign certificates? Well, it is signed by CloudFlare.com. 

How do you know that this signature is valid? Well, every browser and Operating System comes shipped with a bunch of *root certificates*, which are a list of a few hundred pre-trusted websites. If CloudFlare website is in there (which it is!), then by extension the sni.cloudslaressl.com certificate is safe, and by extension the nim-lang.org certificate is also safe! 

This is called Certificate Verification, and it's an important step which we will see next.

### SSL context initialization

To create an SSL context, the newContext function in `lib/pure/net.nim` is called. This function can be configured with the following inputs:
  1. The protocol version, namely SSLv2, SSLv3, TLSv1. If you have the choice, TLS is the newer protocol, and you should use it if you are able. SSL v2 and v3 have been deprecated since 2011 and 2015 respectively. The default is a compatibility protocol which works with all three.
  1. Certificate verification option. There are three options for verify mode: `CVerifyNone`: certificates are not verified; `CVerifyPeer`: certificates are verified; `CVerifyPeerUseEnvVars`: certificates are verified and the optional environment variables SSL_CERT_FILE and SSL_CERT_DIR are also used to locate certificates. By default, CVerifyPeer is used. However, in HTTP Client, CVerifyNone is used.

CA certificates will be loaded, in the following order, from:
  - caFile, caDir, parameters, if set
  - if `verifyMode` is set to `CVerifyPeerUseEnvVars`,
   the SSL_CERT_FILE and SSL_CERT_DIR environment variables are used
  - a set of files and directories from the `ssl_certs` file.

In the `ssl_certs` file, we see a list that looks like this:
```nim
const certificate_paths = [
    # Debian, Ubuntu, Arch: maintained by update-ca-certificates, SUSE, Gentoo
    # NetBSD (security/mozilla-rootcerts)
    # SLES10/SLES11, https://golang.org/issue/12139
    "/etc/ssl/certs/ca-certificates.crt",
    # OpenSUSE
    "/etc/ssl/ca-bundle.pem",
    # --------- snipped --------
```

Interestingly, we see that the Windows certificate paths don't seem to be maintained. In Nim [issue #782](https://github.com/nim-lang/Nim/issues/782) we see that the reason is Windows' OpenSSL version is too low to perform modern certificate validation. 

Certificate verification in Nim was implemented in [this PR](https://github.com/nim-lang/Nim/pull/13697).





