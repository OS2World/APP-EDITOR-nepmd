The MD5 message digest utility
==============================

Overview
--------

(Note: the term 'message' really means an arbitrarily long sequence
of bytes; thus, the contents of a file are a 'message').

The MD5 utility takes as input a message of arbitrary length and
produces as output a 128-bit 'fingerprint' or 'message digest' of the
input.  It is conjectured that it is computationally infeasible to
produce two messages having the same message digest, or to produce any
message having a given prespecified target message digest.

The MD5 algorithm is intended for digital signature applications, where
a large file must be `compressed' in a secure manner before being
encrypted with a private (secret) key under a public-key cryptosystem
such as RSA.  MD5 digests are often provided with large files for
downloading, the idea being that the downloader is told the MD5 digest
for the file, and can thus check that it has been downloaded correctly
by running MD5 over the file and comparing the digest with the one
provided.

Using the program
-----------------

Synopsis: md5 [-pqrtx] [-s string] [file ...]
 Options:
    -h           display this help
    -p           echo input to output, and append the digest value
    -q           quiet mode; generate only the MD5 digest. Overrides -r
    -r           reverse the format of the output; does nothing when
                 combined with the -ptx options
    -s string    generate a digest of string
    -t           run a built-in time trial
    -x           run a built-in test script; -q and -r must precede this
                 option to be effective

Acknowledgement
---------------

This program was placed in the public domain for free general use by RSA
Data Security. It was ported to OS/2 by Bob Eager, rde@tavi.co.uk. The source
code will be provided on request.

Versions
--------
1.0	- Initial version.
1.1	- Support wildcards for file list on command line.

Bob Eager
December 2002

