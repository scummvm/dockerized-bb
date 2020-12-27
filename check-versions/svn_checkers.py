import urllib.request as urlr
import urllib.parse as urlp
import xml.etree.ElementTree as ET

import checkers
import svn_protocol

def parse_multistatus(baseurl, data):
    if data.tag != '{DAV:}multistatus':
        raise Exception("Expected {DAV:}multistatus")
    items = data.iterfind('./{DAV:}response')
    all_files = dict()
    for item in items:
        status = item.find('.//{DAV:}status')
        if status is None:
            raise Exception("Missing {DAV:}status in response")
        status_code = int(status.text.split(' ', 2)[1])
        if status_code != 200:
            continue

        href = item.find('./{DAV:}href')
        if href is None:
            raise Exception("Missing {DAV:}href in response")
        href = href.text

        href = urlp.urljoin(baseurl, href)

        all_props = dict()
        for prop in item.findall('./{DAV:}propstat/{DAV:}prop/*'):
            all_props[prop.tag] = prop.text

        all_files[href] = all_props

    return all_files

@checkers.cache
def fetch_props(url, depth, props):
    parts = urlp.urlsplit(url, allow_fragments=False)
    if parts.scheme.lower() not in('http' ,'https'):
        raise Exception("HTTP and HTTPS are the only schemes supported for SVN protocol for {0}".format(url))
    tags_url = urlp.urlunsplit(parts)

    propfind = ET.Element('{DAV:}propfind')
    prop = ET.SubElement(propfind, '{DAV:}prop')
    for p in props:
        ET.SubElement(prop, p)

    data = ET.tostring(propfind, encoding="utf-8")

    req = urlr.Request(url, method="PROPFIND", data=data)
    req.add_header('Depth', str(depth))
    with urlr.urlopen(req) as reply:
        if reply.status != 207:
            raise Exception("Can't load SVN informations for {0}".format(repository))

        data = ET.fromstring(reply.read())

        return parse_multistatus(url, data)

def dav_get_version(repository):
    objects = fetch_props(repository, 0, ('{DAV:}version-name', ))
    # Reply has only 1 item
    props = next(iter(objects.values()))

    online_version = props['{DAV:}version-name']

    return online_version

def svn_get_version(repository):
    with svn_protocol.SVNClient(repository) as client:
        props = client.get_props('')
    online_version = props[b'svn:entry:committed-rev'].decode('utf-8')

    return online_version

def dav_list_tags(repository):
    objects = fetch_props(repository, 1, tuple())
    urls = objects.keys()

    # Unquote, isolate path and remove leading /
    basepath = urlp.urlsplit(urlp.unquote(repository)).path.rstrip('/')
    # Remove double / but keep the first one
    basepath = basepath.split('/')
    basepath[1:] = filter(None, basepath[1:])
    basepath = '/'.join(basepath)
    # Unquote, isolate path and remove trailing /
    # URLs are already normalized by urljoin
    paths = (urlp.urlsplit(urlp.unquote(url)).path.rstrip('/') for url in urls)

    # Remove basepath (we don't need current directory, only children)
    names = (path.rsplit('/', 1)[1] for path in paths if path != basepath)
    return names

def svn_list_tags(repository):
    with svn_protocol.SVNClient(repository) as client:
        entries = client.get_entries('', None, tuple())
    if entries is None:
        raise Exception("Can't list SVN entries for {0}".format(repository))

    names = (entry.name.decode('utf-8') for entry in entries)
    return names

def svn_commit(version, *, repository):
    parts = urlp.urlsplit(repository, allow_fragments=False)
    if parts.scheme.lower() == 'svn':
        online_version = svn_get_version(repository)
    elif parts.scheme.lower() in('http' ,'https'):
        online_version = dav_get_version(repository)
    else:
        raise Exception("Scheme {0} not supported as SVN protocol for {1}".format(parts.scheme.lower(), repository))

    return online_version == version, online_version, "repository URL: {0}".format(repository)

checkers.register('svn commit', svn_commit)

def svn_tag(version, *, repository, **kwargs):
    parts = urlp.urlsplit(repository, allow_fragments=False)
    if parts.scheme.lower() == 'svn':
        names = svn_list_tags(repository)
    elif parts.scheme.lower() in('http' ,'https'):
        names = dav_list_tags(repository)
    else:
        raise Exception("Scheme {0} not supported as SVN protocol for {1}".format(parts.scheme.lower(), repository))

    # Apply user filters, change delimiter and sort
    matching_tags = checkers.prepare_versions(names, **kwargs)

    if len(matching_tags) == 0:
        print("WARNING: no matching tags for {0} with {1}".format(
            repository, checkers.describe_filter(**kwargs)))
        return True, 'none', "repository URL: {0}".format(repository)

    try:
        current_idx = matching_tags.index(version)
    except ValueError:
        print("WARNING: version {2} not in matched tags for {0} with {1}".format(
            repository, checkers.describe_filter(**kwargs)),
            version)
        current_idx = -1

    latest = matching_tags[0]

    return current_idx == 0, latest, "repository URL: {0}".format(repository)

checkers.register('svn tag', svn_tag)
