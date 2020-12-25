import collections.abc as abc
from functools import lru_cache
import re
import time

import versioning

__all__ = [
    # Cache functions
    "stats", "cache",
    # Checkers management
    "register", "lookup", "BadConfigException"
    # Helpers for checkers
    "prepare_versions", "filter_versions", "describe_filter"
]

__CHECKERS = dict()
__CACHE = list()

# Arguments can't contain these characters, map them
__ARGS_TRANS_TABLE = str.maketrans(" -","__")

class BadConfigException(Exception):
    pass

def __get_checker(checker_name):
    checker = __CHECKERS.get(checker_name, None)
    if checker is None:
        raise Exception("Invalid checker '{0}', valid ones are {1}".format(
            checker_name, ' '.join("'{0}'".format(checker_name)
                for checker_name in __CHECKERS.keys())))
    return checker

def register(name, func):
    __CHECKERS[name] = func

def lookup(checker):
    # String is a sequence, check it before
    if isinstance(checker, str):
        name = checker
        args = {}
    elif isinstance(checker, abc.Sequence):
        name = checker[0]
        args = checker[1]
        if not isinstance(args, abc.Mapping):
            raise BadConfigException("Invalid check configuration: should be ('checkname', {{ args... }}) not\n{0!r}".format(checker))
    elif isinstance(checker, abc.Mapping):
        if "check" not in checker:
            raise BadConfigException("Invalid check configuration: should be {{ 'check': 'checkname', args... }} not\n{0!r}".format(checker))
        name = checker["check"]

        args = {k.translate(__ARGS_TRANS_TABLE): v
                for k, v in checker.items() if k != "check"}
    else:
        raise BadConfigException("Invalid check configuration")

    return __get_checker(name), args

def cache(func):
    __CACHE.append(lru_cache(typed=True)(func))
    return __CACHE[-1]

def stats():
    for cache in __CACHE:
        print("{0}: {1!r}".format(cache.__name__, cache.cache_info()))

# Helpers functions to filter stuff
def match_version(version, *, pattern=None, exclude_pattern=None, prefix='', suffix='', **kwargs):
    return (
            version.startswith(prefix) and
            version.endswith(suffix) and
            (pattern is None or re.match(pattern, version)) and
            (exclude_pattern is None or not re.match(exclude_pattern, version))
        )

def cleanup_version(version, *, prefix='', suffix='', **kwargs):
    return version[len(prefix):len(version)-len(suffix)]

def filter_versions(versions, **kwargs):
    return [cleanup_version(version, **kwargs)
            for version in versions
            if match_version(version, **kwargs)]

def prepare_versions(versions, *, delimiter='.', **kwargs):
    versions = filter_versions(versions, **kwargs)

    # Apply delimiter here too, that's more shared code
    if delimiter != '.':
        trans = str.maketrans(delimiter, '.')
        versions = [versions.translate(trans) for version in versions]

    versions.sort(key=versioning.Version, reverse=True)

    return versions

def describe_filter(pattern=None, exclude_pattern=None, prefix='', suffix='', **kwargs):
    return "prefix {0!r}, suffix {1!r}, {2} and {3}".format(
            prefix, suffix,
            "pattern {0!r}".format(pattern) if pattern else "no pattern",
            "exclude pattern {0!r}".format(exclude_pattern) if exclude_pattern else "no exclude pattern",
            )

# Ignore checker: doesn't do anything
def ignore(version):
    return True, 'ignored', ''
register('ignore', ignore)

import docker_checkers
import hg_checkers
import git_checkers
import svn_checkers
import web_checkers
