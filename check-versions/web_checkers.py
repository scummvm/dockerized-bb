import json
import re
import urllib.request as urlr
import urllib.parse as urlp

import checkers

@checkers.cache
def fetch_page(url, *, encoding=None, context=None, **kwargs):
    # Don't pass all kwargs because some are not for Request
    kwargs = { k: v for k, v in kwargs.items() if k in ['data', 'headers', 'method'] }

    req = urlr.Request(url, **kwargs)
    with urlr.urlopen(req, context=context) as reply:
        if not (200 <= reply.status < 300):
            raise Exception("Can't load web page at URL {0}".format(url))

        if encoding is None:
            # Try automatic detection based on Content-Type
            content_type = reply.getheader('Content-Type')
            parts = [p.strip() for p in content_type.split(';')]
            for p in parts:
                if p.lower().startswith('charset='):
                    encoding = p[8:]
                    break

        # No encoding could be determined, try ascii
        if encoding is None:
            encoding = "ascii"

        data = reply.read()
        # If user specified bytes fake encoding, don't decode
        if encoding != "bytes":
            data = data.decode(encoding)

        return data

def scrape(version, *, url, filter_pattern, all_versions=False, case_insensitive=False, **kwargs):
    data = fetch_page(url, **kwargs)

    versions = re.finditer(filter_pattern, data)
    versions = [match.group('version') for match in versions]

    # Apply user filters, change delimiter and sort
    versions = checkers.prepare_versions(versions, **kwargs)

    if len(versions) == 0:
        print("WARNING: no matching versions for {0}, pattern {1} with {2}".format(
            url, filter_pattern,
            checkers.describe_filter(**kwargs)))
        return True, 'none', "page URL: {0}".format(url)

    if case_insensitive:
        version = version.lower()
        versions = [version.lower() for version in versions]

    # On a webpage you may not have all versions so don't warn if not expected
    try:
        current_idx = versions.index(version)
    except ValueError:
        if all_versions:
            print("WARNING: version {3} not in versions for {0}, pattern {1} and with {2}".format(
                url, filter_pattern,
                checkers.describe_filter(**kwargs)), version)
        current_idx = -1

    latest = versions[0]

    return current_idx == 0, latest, "page URL: {0}".format(url)

checkers.register('scrape', scrape)

def apple_store(version, *, productid):
    if not isinstance(productid, str):
        productid = str(productid)
    url = "https://itunes.apple.com/lookup?id=" + str(productid)

    # Data will be JSON
    data = fetch_page(url)

    data = json.loads(data)
    if ('resultCount' not in data or
        'results' not in data):
        raise Exception('Error while loading Apple informations')

    count = data['resultCount']
    if count <= 0:
        raise Exception('Apple Product ID {0} not found'.format(productid))
    elif count > 1:
        print('WARNING: Apple Product ID {0} not unique, taking first'.format(productid))

    product = data['results'][0]
    if ('version' not in product or
        'trackName' not in product):
        raise Exception('No version while loading Apple informations')

    latest = product['version']

    return version == latest, latest, "product ID: {0}, product name: {1}".format(productid, product['trackName'])

checkers.register('apple store', apple_store)
