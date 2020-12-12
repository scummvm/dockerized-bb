import json
import re
import time
import calendar
import urllib.error as urle
import urllib.parse as urlp
import urllib.request as urlr

import checkers

TOKEN = '[!#$%&\'*+.^_`|~A-Za-z0-9-]+'
TOKEN68 = r'[A-Za-z0-9._~+/-]+=*'
AUTH_SCHEME_RE = re.compile(r'(?P<scheme>{0})\s+'.format(TOKEN))
AUTH_TOKEN68 = re.compile(r'(?P<value>{0})\s*(?:,|$)'.format(TOKEN68))
AUTH_PARAM_RE = re.compile(r'\s*(?P<key>{0})\s*=\s*(?:(?P<value>{0})|"(?P<valueQ>(?:\\.|[^"\\])*)")\s*(?:,|$)'.format(TOKEN))

def parse_authline(authline):
    """Parse according to RFC7235"""
    challenges = dict()
    authline = authline.strip(' ')
    while True:
        scheme = AUTH_SCHEME_RE.match(authline)
        if scheme is None:
            break
        # Remove auth scheme
        authline = authline[scheme.end():]
        scheme = scheme.group('scheme').lower()

        tok68 = AUTH_TOKEN68.match(authline)
        if tok68 is not None:
            # A unique base64ish parameter
            challenges[scheme] = tok68.group('value')
            authline = authline[tok68.end():]
            continue

        params = dict()
        challenges[scheme] = params
        while True:
            param = AUTH_PARAM_RE.match(authline)
            if param is None:
                break
            authline = authline[param.end():]

            value = param.group('value')
            if not value:
                value = re.sub(r'\\(.)', '\1', param.group('valueQ'))
            params[param.group('key').lower()] = value
    return challenges

def authenticate(registry, authline):
    challenges = parse_authline(authline)

    if 'bearer' not in challenges:
        raise Exception("Can't find authentication information in header for {0}".format(registry))

    realm = challenges['bearer']['realm']
    service = challenges['bearer']['service']
    scope = challenges['bearer']['scope']

    query = 'service={0}&scope={1}&client_id=check-versions'.format(
            urlp.quote_plus(service), urlp.quote_plus(scope))

    parts = urlp.urlsplit(realm, allow_fragments=False)
    parts = (parts.scheme, parts.netloc,
            parts.path,
            query, '')
    auth_url = urlp.urlunsplit(parts)

    req = urlr.Request(auth_url, method='GET')
    with urlr.urlopen(req) as reply:
        if reply.status != 200:
            raise Exception("Can't authenticate for {0}".format(registry))
        data = json.load(reply)

    token = data.get('token', None) or data.get('access_token', None)
    if token is None:
        raise Exception("Couldn't get token for {0}".format(registry))
    expires_in = data.get('expires_in', 60)
    issued_at = data.get('issued_at', None)
    if issued_at:
        if issued_at[-1] != 'Z':
            raise Exception("Invalid issued_at time {0}".format(issued_at))
        # %f limits at 6 digits
        issued_at = issued_at[0:issued_at.rindex('.')+6]
        issued_at = calendar.timegm(time.strptime(issued_at, '%Y-%m-%dT%H:%M:%S.%f'))
    else:
        issued_at = time.time()
    refresh_token = data.get('refresh_token', None)

    expires_at = issued_at + expires_in

    return token

def parse_manifest(reply, **kwargs):
    # When we have only one manifest, we only need to get the Digest header
    return reply.getheader('Docker-Content-Digest')

def make_filter(name, value):
    if isinstance(value, str):
        crit = value.__eq__
    elif isinstance(value, collections.abc.Iterable):
        # features are lists, make them sets
        value = set(value)
        crit = value.issubset
    else:
        value = str(value)
        crit = value.__eq__
    return lambda p: crit(p[1].get(name, None))

def parse_fat_manifest(reply, **kwargs):
    manifest_l = json.load(reply)

    if manifest_l.get('schemaVersion', None) != 2:
        raise Exception("Invalid manifest version {1} for {0}".format(reply.url, manifest_l.get('schemaVersion', None)))

    if manifest_l.get('mediaType', None) != 'application/vnd.docker.distribution.manifest.list.v2+json':
        raise Exception("Invalid manifest mediaType {1} for {0}".format(reply.url, manifest_l.get('mediaType', None)))

    platforms = ((i, manifest['platform']) for i, manifest in enumerate(manifest_l['manifests']))
    for name, value in kwargs.items():
        # Apply filter specified in arguments
        platforms = filter(make_filter(name, value), platforms)

    # Make it a list and apply all filters
    platforms = list(platforms)
    if len(platforms) == 0:
        raise Exception("No matching platform for {0}".format(reply.url))

    if len(platforms) > 1:
        print("WARNING: Multiple platforms match query for {0}: {1!r}".format(reply.url, platforms))

    manifest = manifest_l['manifests'][platforms[0][0]]

    return manifest['digest']

def _fetch_digest(registry, image_name, reference, *, full=False, token=None, **kwargs):
    parts = urlp.urlsplit(registry, allow_fragments=False)
    if parts.scheme.lower() not in('http' ,'https'):
        raise Exception("HTTP and HTTPS are the only schemes supported as Docker for {0}".format(registry))

    parts = (parts.scheme, parts.netloc,
            '/v2/{0}/manifests/{1}'.format(image_name, reference),
            '', '')
    manifest_url = urlp.urlunsplit(parts)

    # Avoid to use GET when we can to not trigger pull rate limits
    method = 'GET' if full else 'HEAD'

    req = urlr.Request(manifest_url, method=method)
    req.add_header('Accept', 'application/vnd.docker.distribution.manifest.list.v2+json, application/vnd.docker.distribution.manifest.v2+json')
    if token is not None:
        req.add_header('Authorization', 'Bearer {0}'.format(token))
    try:
        with urlr.urlopen(req) as reply:
            content_type = reply.getheader('Content-Type')
            if content_type == 'application/vnd.docker.distribution.manifest.list.v2+json':
                # For manifest list we really need the content
                if full:
                    digest = parse_fat_manifest(reply, **kwargs)
                else:
                    return _fetch_digest(registry, image_name, reference, token=token, full=True, **kwargs)
            elif content_type == 'application/vnd.docker.distribution.manifest.v2+json':
                digest = parse_manifest(reply, **kwargs)
            else:
                raise Exception("Unsupported Content-Type returned {1} for {0}".format(manifest_url, content_type))
    except urle.HTTPError as reply:
        if reply.status == 401 and token is None:
            # We are not authenticated
            authline = reply.getheader('WWW-Authenticate')
            token = authenticate(registry, authline)
            try:
                return _fetch_digest(registry, image_name, reference, token=token, **kwargs)
            except Exception as e:
                # Clear context when calling after proper authentication
                raise e from None

        raise Exception("Can't load image manifest for {0}".format(manifest_url), reply)

    return digest

@checkers.cache
def fetch_digest(registry, image_name, reference, **kwargs):
    return _fetch_digest(registry, image_name, reference, **kwargs)

# Criterion are based on platform field in Docker manifests: https://docs.docker.com/registry/spec/manifest-v2-2/#manifest-list-field-descriptions
def docker_tag(version, *, registry, image_name, reference='latest', tag_format=None, **kwargs):
    # Fetch monitored refence first
    latest_digest = fetch_digest(registry, image_name, reference, **kwargs)

    # Build the tag name from the version in the file
    if tag_format is not None:
        version = tag_format.format(version)

    # Now fetch its digest
    file_digest = fetch_digest(registry, image_name, version, **kwargs)

    return latest_digest == file_digest, reference, "Registry URL: {0}, image {1}".format(registry, image_name)

checkers.register('docker tag', docker_tag)

if __name__ == "__main__":
    print(fetch_digest('https://registry-1.docker.io', 'gitlab/gitlab-ce', 'latest'))
    print(fetch_digest('https://registry-1.docker.io', 'library/docker', 'latest', architecture='amd64', os='linux'))
