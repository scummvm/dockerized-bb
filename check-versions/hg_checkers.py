import urllib.request as urlr
import urllib.parse as urlp

import checkers

@checkers.cache
def lookup(repository, obj, context=None):
    parts = urlp.urlsplit(repository, allow_fragments=False)
    if parts.scheme.lower() not in('http' ,'https'):
        raise Exception("HTTP and HTTPS are the only schemes supported as Mercurial protocol for {0}".format(repository))

    parts = (parts.scheme, parts.netloc,
            parts.path,
            urlp.urlencode({
                'cmd': 'lookup',
                'key': obj,
            }), "")
    lookup_url = urlp.urlunsplit(parts)

    req = urlr.Request(lookup_url, method="GET")
    with urlr.urlopen(req, context=context) as reply:
        content_type = reply.getheader('Content-Type')
        if content_type != 'application/mercurial-0.1':
            raise Exception("Invalid Content-Type received when looking up object for {0}".format(repository))

        data = reply.read()
        data = data.rstrip(b'\n')
        result, obj = data.split(b' ', maxsplit=1)

        if result == b'0':
            raise Exception("Error received when looking up for {0}: {1}".format(repository, obj))

        if result != b'1':
            raise Exception("Invalid reply when looking up for {0}: {1}".format(repository, data))

    return obj.decode('ascii')

@checkers.cache
def tags(repository, head, context=None):
    # This is kind of a hack: we just download .hgtags from specified head using hgweb
    # Not really the proper way

    parts = urlp.urlsplit(repository, allow_fragments=False)
    if parts.scheme.lower() not in('http' ,'https'):
        raise Exception("HTTP and HTTPS are the only schemes supported as Mercurial protocol for {0}".format(repository))

    parts = (parts.scheme, parts.netloc,
            "{0}/raw-file/{1}/.hgtags".format(parts.path.rstrip('/'), head),
            "", "")
    lookup_url = urlp.urlunsplit(parts)

    req = urlr.Request(lookup_url, method="GET")
    with urlr.urlopen(req, context=context) as reply:
        data = reply.read()
        refs = dict()
        for line in data.split(b'\n'):
            obj, tagname = line.split(b' ', maxsplit=1)
            # Last tag override older ones (file is append only)
            refs[tagname.decode('utf-8')] = obj.decode('ascii')

    return refs

def hg_commit(version, *, repository, branch, context=None):
    obj = lookup(repository, branch, context)

    shortobj = obj
    if len(version) > 0 and len(version) < len(obj):
        shortobj = obj[:len(version)]

    return shortobj == version, obj, "repository URL: {0} branch {1}".format(repository, branch)

checkers.register('hg commit', hg_commit)

def hg_tag(version, *, repository, head="tip", context=None, **kwargs):
    refs = tags(repository, head, context)

    matching_refs = list(refs.keys())

    refs = None

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
            repository, checkers.describe_filter(**kwargs)),
            version)
        current_idx = -1

    latest = matching_refs[0]

    return current_idx == 0, latest, "repository URL: {0}".format(repository)

checkers.register('hg tag', hg_tag)
