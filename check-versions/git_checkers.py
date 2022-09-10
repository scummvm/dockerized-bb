import urllib.request as urlr
import urllib.parse as urlp

import checkers

# Sentinel values
FLUSH_PKT = object()
DELIM_PKT = object()
ENDRS_PKT = object()

def read_packet_line(reply):
    length = reply.read(4)
    if len(length) != 4:
        raise Exception("Invalid git packet line length for {0}".format(reply.geturl()))
    length = int(length, 16)
    if length < 4:
        if length == 0:
            return FLUSH_PKT
        elif length == 1:
            return DELIM_PKT
        elif length == 2:
            return ENDRS_PKT
        else:
            raise Exception("Invalid git length tag for {0}".format(reply.geturl()))
    data = reply.read(length - 4)
    if data.endswith(b'\n'):
        data = data[:-1]
    return data

def parse_dumb_refs(reply):
    refs = list()
    for line in reply.read().split(b'\n'):
        obj, ref = line.split(b'\t', 1)
        obj = obj.decode('ascii')
        ref = ref.decode('utf-8')
        if ref.endswith('^{}'):
            # This is a peeled reference
            # We are more interested in this one than the previous one which points to a tag object
            ref = ref[:-3]
            if len(refs) == 0 or refs[-1][0] != ref:
                raise Exception("Invalid peeled object for {0}".format(reply.geturl()))
            refs[-1] = (ref, obj)
            continue
        refs.append((ref, obj))
    refsd = dict(refs)
    if len(refsd) != len(refs):
        raise Exception("Duplicate references in list for {0}".format(reply.geturl()))
    return refs

def parse_smart_refs(reply):
    data = read_packet_line(reply)
    if data != b"# service=git-upload-pack":
        raise Exception("Invalid Git header line: {0!r} for {1}".format(data, reply.geturl()))
    data = read_packet_line(reply)
    if data is not FLUSH_PKT:
        raise Exception("Missing Git flush packet for {0}".format(reply.geturl()))
    data = read_packet_line(reply)
    version = 0
    if data.startswith(b"version "):
        data = data.rstrip(b'\n')
        # We are version 1+
        version = int(data[8:])
        # Read next line to be on par with version 0 case
        data = read_packet_line(reply)

    refs = list()
    while data is not FLUSH_PKT:
        data = data.rstrip(b'\n')
        obj, ref = data.split(b' ', 1)
        if len(refs) == 0:
            # First line contains capabilities
            ref, cap_list = ref.split(b'\0', 1)
            if obj == b'0'*len(obj) and ref == b'capabilities^{}':
                # Empty list next packet will be flush
                data = read_packet_line(reply)
                break
        obj = obj.decode('ascii')
        ref = ref.decode('utf-8')
        if ref.endswith('^{}'):
            # This is a peeled reference
            # We are more interested in this one than the previous one which points to a tag object
            ref = ref[:-3]
            if len(refs) == 0 or refs[-1][0] != ref:
                raise Exception("Invalid peeled object for {0}".format(reply.geturl()))
            refs[-1] = (ref, obj)
            data = read_packet_line(reply)
            continue
        refs.append((ref, obj))
        data = read_packet_line(reply)

    assert(data is FLUSH_PKT)
    assert(reply.read() == b'')

    refsd = dict(refs)
    if len(refsd) != len(refs):
        raise Exception("Duplicate references in list for {0}".format(reply.geturl()))
    return refsd

@checkers.cache
def fetch_refs(repository, context=None):
    parts = urlp.urlsplit(repository, allow_fragments=False)
    if parts.scheme.lower() not in('http' ,'https'):
        raise Exception("HTTP and HTTPS are the only schemes supported for Git protocol for {0}".format(repository))

    parts = (parts.scheme, parts.netloc,
            "{0}/info/refs".format(parts.path),
            "service=git-upload-pack", "")
    refs_url = urlp.urlunsplit(parts)

    req = urlr.Request(refs_url, method="GET")
    # We don't support v2
    req.add_header('Git-Protocol', 'version=1')
    with urlr.urlopen(req, context=context) as reply:
        if reply.status != 200:
            raise Exception("Can't load Git references for {0}".format(repository))

        content_type = reply.getheader('Content-Type')
        if content_type == 'application/x-git-upload-pack-advertisement':
            refs = parse_smart_refs(reply)
        else:
            refs = parse_dumb_refs(reply)
    return refs

def git_commit(version, *, repository, branch, context=None):
    refs = fetch_refs(repository, context)

    ref_name = 'refs/heads/{0}'.format(branch)
    obj = refs.get(ref_name, None)

    if obj is None:
        raise Exception("Invalid branch {1} specified for {0}".format(repository, branch))

    return obj == version, obj, "repository URL: {0} branch {1}".format(repository, branch)

checkers.register('git commit', git_commit)

def git_tag(version, *, repository, context=None, **kwargs):
    refs = fetch_refs(repository, context)

    matching_refs = list(refs.keys())

    refs = None

    # Remove refs/tag prefix
    matching_refs = checkers.filter_versions(matching_refs, prefix='refs/tags/')

    # Apply user filters, change delimiter and sort
    matching_refs = checkers.prepare_versions(matching_refs, **kwargs)

    if len(matching_refs) == 0:
        print("WARNING: no matching references for {0} with {1}".format(
            repository, checkers.describe_filter(**kwargs)))
        return True, 'none', "repository URL: {0}".format(repository)

    try:
        current_idx = matching_refs.index(version)
    except ValueError:
        print("WARNING: version {2} not in matched references for {0} with {1}".format(
            repository, checkers.describe_filter(**kwargs), version))
        current_idx = -1

    latest = matching_refs[0]

    return current_idx == 0, latest, "repository URL: {0}".format(repository)

checkers.register('git tag', git_tag)
