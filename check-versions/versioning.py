"""
This module implements the version sort of coreutils taken from Debian
"""

import re
from itertools import zip_longest
from functools import total_ordering

__all__ = [ "Version" ]

EXT_RE = re.compile(rb'(?:\.[A-Za-z~][A-Za-z0-9~]*)*$')

EMPTY_VERSION = object()
CURRENT_DIR = object()
PARENT_DIR = object()

HIDDEN_PREFIX = object()

@total_ordering
class VersionString(bytes):
    """
    String part of a version used to create custom ordering rules
    """
    __slots__ = []

    # Not supposed to contain any digit
    def __lt__(self, other):
        #if super().__eq__(other):
        if self == other:
            return False
        # If other is an int, use an empty bytes because it will get filled by 0s
        if isinstance(other, int):
            other = b''
        if not isinstance(other, bytes):
            return NotImplemented

        # If one part is short, it's like a digit (next part is a digit)
        for s, o in zip_longest(self, other, fillvalue=b'0'[0]):
            if s == o:
                continue
            s_b = bytes([s])
            o_b = bytes([o])
            #if s_b.isdigit() and o_b.isdigit():
            #    continue
            if s_b == b'~':
                return True
            if o_b == b'~':
                return False
            if s_b.isdigit():
                return True
            if o_b.isdigit():
                return False
            if s_b.isalpha() and o_b.isalpha():
                return s < o
            if s_b.isalpha():
                return True
            if o_b.isalpha():
                return False
            return s < o

@total_ordering
class Version:
    """
    Version is a sorting helper implementing coreutils alternative of Debian version sorting algorithm
    """
    __slots__ = ["vstring", "flag",
            "compstring", "suffstring",
            "components", "suffix"]

    def __init__(self, vstring=None):
        """
        Creates a Version using parse method
        """
        if not vstring:
            vstring = ""
        self.parse(vstring)

    def parse(self, s):
        """
        Parse a version and setup the Version object for sorting
        """
        self.vstring = s
        if isinstance(s, str):
            s = s.encode('utf-8')

        self.flag = None
        self.compstring = b''
        self.suffstring = b''
        self.components = list()
        self.suffix = list()

        if len(s) == 0:
            self.flag = EMPTY_VERSION
            return

        if s == b'.':
            self.flag = CURRENT_DIR
            return
        if s == b'..':
            self.flag = PARENT_DIR
            return

        if s[0:1] == b'.':
            self.flag = HIDDEN_PREFIX
            s = s[1:]

        suffix_s = EXT_RE.search(s).group(0)
        s = s[:len(s)-len(suffix_s)]

        components = self.__parse_components(s)

        if suffix_s:
            suffix = self.__parse_components(suffix_s)
        else:
            suffix = list()

        self.compstring = s
        self.components = components
        self.suffstring = suffix_s
        self.suffix = suffix

    def __parse_components(self, s):
        """
        Parses a part of the version, either main part of suffix part
        """
        components = list()
        buf = b''
        in_digit = False
        for b_i in s:
            b = bytes([b_i])
            if in_digit and not b.isdigit():
                # Numeric part
                components.append(int(buf, 10))
                in_digit = False
                buf = b''
            elif not in_digit and b.isdigit():
                components.append(VersionString(buf))
                in_digit = True
                buf = b''
            buf += b
        if buf:
            if in_digit:
                # Numeric part
                components.append(int(buf, 10))
            else:
                components.append(VersionString(buf))
        return components

    def __eq__(self, other):
        """
        Checks version equality, first by comparing components then by comparing string wise
        """
        if not isinstance(other, Version):
            return NotImplemented

        if self.flag != other.flag:
            return False

        if self.compstring == other.compstring:
            self_c = self.suffix
            other_c = other.suffix
        else:
            self_c = self.components
            other_c = other.components

        if self_c == other_c:
            return self.vstring == other.vstring
        else:
            return False

    def __lt__(self, other):
        """
        Where the sorting magic happens
        """
        if not isinstance(other, Version):
            return NotImplemented
        # Simple case first
        if self.vstring == other.vstring:
            return False

        # For following flags, if they are equals it's treated by vstring equality
        if self.flag == EMPTY_VERSION:
            return True
        if other.flag == EMPTY_VERSION:
            return False

        if self.flag == CURRENT_DIR:
            return True
        if other.flag == CURRENT_DIR:
            return False

        if self.flag == PARENT_DIR:
            return True
        if other.flag == PARENT_DIR:
            return False

        if self.flag == HIDDEN_PREFIX and other.flag != HIDDEN_PREFIX:
            return True
        if other.flag == HIDDEN_PREFIX and self.flag != HIDDEN_PREFIX:
            return False

        if self.compstring == other.compstring:
            self_c = self.suffix
            other_c = other.suffix
        else:
            self_c = self.components
            other_c = other.components

        for self_p, other_p in zip_longest(self_c, other_c, fillvalue=VersionString()):
            if self_p == other_p:
                continue
            return self_p < other_p

VERSIONS = [
    "",
    ".",
    "..",
    ".0",
    ".9",
    ".A",
    ".Z",
    ".a~",
    ".a",
    ".b~",
    ".b",
    ".z",
    ".zz~",
    ".zz",
    ".zz.~1~",
    ".zz.0",
    "0",
    "9",
    "A",
    "Z",
    "a~",
    "a",
    "a.b~",
    "a.b",
    "a.bc~",
    "a.bc",
    "b~",
    "b",
    "gcc-c++-10.fc9.tar.gz",
    "gcc-c++-10.fc9.tar.gz.~1~",
    "gcc-c++-10.fc9.tar.gz.~2~",
    "gcc-c++-10.8.12-0.7rc2.fc9.tar.bz2",
    "gcc-c++-10.8.12-0.7rc2.fc9.tar.bz2.~1~",
    "glibc-2-0.1.beta1.fc10.rpm",
    "glibc-common-5-0.2.beta2.fc9.ebuild",
    "glibc-common-5-0.2b.deb",
    "glibc-common-11b.ebuild",
    "glibc-common-11-0.6rc2.ebuild",
    "libstdc++-0.5.8.11-0.7rc2.fc10.tar.gz",
    "libstdc++-4a.fc8.tar.gz",
    "libstdc++-4.10.4.20040204svn.rpm",
    "libstdc++-devel-3.fc8.ebuild",
    "libstdc++-devel-3a.fc9.tar.gz",
    "libstdc++-devel-8.fc8.deb",
    "libstdc++-devel-8.6.2-0.4b.fc8",
    "nss_ldap-1-0.2b.fc9.tar.bz2",
    "nss_ldap-1-0.6rc2.fc8.tar.gz",
    "nss_ldap-1.0-0.1a.tar.gz",
    "nss_ldap-10beta1.fc8.tar.gz",
    "nss_ldap-10.11.8.6.20040204cvs.fc10.ebuild",
    "z",
    "zz~",
    "zz",
    "zz.~1~",
    "zz.0",
    "#.b#",
]

def test():
    import random

    randoms = list(VERSIONS)
    random.shuffle(randoms)

    verversions = sorted(randoms, key=Version)
    assert(VERSIONS == verversions)

    for i in range(len(VERSIONS)):
        for j in range(len(VERSIONS)):
            v1 = Version(VERSIONS[i])
            v2 = Version(VERSIONS[j])
            lt = v1 < v2
            eq = v1 == v2
            assert(lt == (i < j))
            assert(eq == (i == j))

if __name__ == "__main__":
    test()
