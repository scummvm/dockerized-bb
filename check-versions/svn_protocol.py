import base64
import collections
import hashlib
import socket
import urllib.parse as urlp

__all__ = ['SVNClient']

class SVNProtocolError(Exception):
    pass

class SVNServerError(SVNProtocolError):
    def __init__(self, msg):
        super().__init__('Server replied with error: {0!r}'.format(msg))
        self.server_error = msg

class SVNString(bytes):
    pass

DirEntry = collections.namedtuple('DirEntry', ['name', 'kind', 'size', 'has_props', 'created_rev', 'created_date', 'last_author'])

class SVNClient:
    def __init__(self, url):
        parts = urlp.urlsplit(url, allow_fragments=False)
        if parts.scheme.lower() != 'svn':
            raise Exception("SVN is the only scheme supported for pure SVN protocol for {0}".format(url))
        self.url = url
        port = parts.port
        if port is None:
            port = 3690
        self.server = (parts.hostname, port)
        self.s = None

    def connect(self):
        if self.s:
            return

        self.s = socket.create_connection(self.server)
        caps = greeting(self.s, self.url)
        result, extra = auth(self.s)
        if not result:
            self.s.close()
            self.s = None
            raise SVNServerError('Authentication failed: {0}'.format(extra.decode('utf-8')))

        self.auth_token = extra

        uuid, repo_url, repo_caps = repos_info(self.s)
        self.uuid = uuid
        self.repo_url = repo_url
        self.caps = caps + repo_caps

    def __enter__(self):
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.s.close()
        self.s = None
        return False

    def get_latest_rev(self):
        return get_latest_rev(self.s)

    def check_path(self, path, rev = None):
        return check_path(self.s, path, rev)

    def get_dir(self, path, rev = None, want_props=False, want_contents=False, dirent_fields=None):
        return get_dir(self.s, path, rev, want_props, want_contents, dirent_fields)

    def get_file(s, path, rev, want_props=False, want_contents=False):
        return get_file(self.s, path, rev, want_props, want_contents)

    def get_props(self, path, rev=None):
        kind = self.check_path(path, rev)
        if kind == b'dir':
            revision, props, entries = self.get_dir(path, rev, True, False, None)
        elif kind == b'file':
            checksum, revision, props, content = self.get_file(path, rev, True, False)
        else:
            props = None
        return props

    def get_entries(self, path, rev=None, dirent_fields=None):
        kind = self.check_path(path, rev)
        if kind == b'dir':
            revision, props, entries = self.get_dir(path, rev, False, True, dirent_fields)
        else:
            entries = None

        return entries

# TOKENS
OPENING_PAREN = object()
CLOSING_PAREN = object()

SPACES = b' \n'
BOOLEANS = [b'false', b'true']
KINDS = [b'none', b'file', b'dir', b'unknown']

def build_reply(obj):
    if type(obj) is SVNString:
        return b'%d:%b ' % (len(obj), obj)
    elif type(obj) is str:
        return b'%d:%b ' % (len(obj), obj.encode('ascii'))
    elif type(obj) is bytes:
        return b'%b ' % (obj, )
    elif type(obj) is int:
        return b'%d ' % (obj, )
    elif type(obj) is bool:
        return b'true ' if obj else b'false '
    elif type(obj) is tuple:
        return b'( %b) ' % (b''.join(
            build_reply(o) for o in obj), )
    else:
        raise Exception("Invalid object type {0!s} when building svn reply", type(obj))

def readit(s, sz=1):
    while True:
        yield s.recv(sz)

def read_string(s, length):
    # Read ending space too
    length += 1
    data = bytearray(length)
    view = memoryview(data)
    while len(view) > 0:
        rln = s.recv_into(view)
        if rln == 0:
            raise SVNProtocolError('Unexpected end of stream while reading a string of length {0}'.format(length))
        view = view[rln:]
    if data[-1:] not in SPACES:
        raise SVNProtocolError('Unexpected character at end of string: {0!r}'.format(data[-1:]))

    return SVNString(data[:-1])

def read_tokens(s):
    buf = None
    for b in readit(s):
        if not b:
            # End of stream
            return
        elif b in SPACES:
            if buf is not None:
                yield buf
                buf = None
            continue
        elif b == b':':
            if type(buf) is not int:
                raise SVNProtocolError('Unexpected colon without digits before: {0!r}'.format(buf))
            yield read_string(s, buf)
            buf = None
        elif b == b')':
            if buf is not None:
                raise SVNProtocolError('Unexpected closing parenthesis after digits or alpha: {0!r}'.format(buf))
            buf = s.recv(1)
            if buf not in SPACES:
                raise SVNProtocolError('Missing space after closing parenthesis: {0!r}'.format(buf))
            yield CLOSING_PAREN
            buf = None
        elif b == b'(':
            if buf is not None:
                raise SVNProtocolError('Unexpected opening parenthesis after digits or alpha: {0!r}'.format(buf))
            buf = s.recv(1)
            if buf not in SPACES:
                raise SVNProtocolError('Missing space after closing parenthesis: {0!r}'.format(buf))
            yield OPENING_PAREN
            buf = None
        elif b.isdigit():
            # Accumulate to buffer
            d = int(b, 10)
            if buf is None:
                buf = d
            elif type(buf) is int:
                buf = buf * 10 + d
            else:
                buf += b
        elif b.isalpha():
            if buf is None:
                buf = b
            elif type(buf) is int:
                raise SVNProtocolError('Unexpected alpha {1!r} after digits: {0!r}'.format(buf, b))
            else:
                buf += b
        elif b == b'-':
            if buf is None:
                raise SVNProtocolError('Unexpected dash out of nowhere')
            elif type(buf) is int:
                raise SVNProtocolError('Unexpected dash after digits: {0!r}'.format(buf, b))
            else:
                buf += b

def read_tuple(s, got_open=False):
    it = read_tokens(s)
    if not got_open:
        try:
            token = next(it)
        except StopIteration:
            raise SVNProtocolError('Unexpected end of stream') from None
        if token is not OPENING_PAREN:
            raise SVNProtocolError('An opening parenthesis was expected, got: {0!r}'.format(token))
    items = list()
    for token in it:
        if token is CLOSING_PAREN:
            return tuple(items)
        elif token is OPENING_PAREN:
            items.append(read_tuple(s, True))
        else:
            items.append(token)
    raise SVNProtocolError('Unexpected end of stream, closing parenthesis expected')

def read_response(s):
    l = read_tuple(s)
    if len(l) != 2:
        raise SVNProtocolError('Unexpected response length, got: {0!r}'.format(l))

    if l[0] == b'success':
        return l[1]

    if l[0] == b'failure':
        raise SVNServerError(l[1])

    raise SVNProtocolError('Unexpected response result, got: {0!r}'.format(l[0]))

def parse_dirent(dirent):
    assert(type(dirent) is tuple)
    assert(len(dirent) == 7)

    assert(type(dirent[0]) is SVNString)
    assert(type(dirent[1]) is bytes and dirent[1] in KINDS)
    assert(type(dirent[2]) is int)
    assert(type(dirent[3]) is bytes and dirent[3] in BOOLEANS)
    assert(type(dirent[4]) is int)
    assert(type(dirent[5]) is tuple)
    assert(len(dirent[5]) == 0 or (len(dirent[5]) == 1 and type(dirent[5][0]) is SVNString))
    assert(type(dirent[6]) is tuple)
    assert(len(dirent[6]) == 0 or (len(dirent[6]) == 1 and type(dirent[6][0]) is SVNString))

    name = dirent[0]
    kind = dirent[1]
    size = dirent[2]
    has_props = dirent[3] == b'true'
    created_rev = dirent[4]
    created_date = None if len(dirent[5]) == 0 else dirent[5][0]
    last_author = None if len(dirent[6]) == 0 else dirent[6][0]

    return DirEntry(name, kind, size, has_props, created_rev, created_date, last_author)

def greeting(s, url):
    server_greeting = read_response(s)
    assert(type(server_greeting) is tuple)
    assert(len(server_greeting) == 4)
    assert(type(server_greeting[0]) is int)
    assert(type(server_greeting[1]) is int)
    assert(type(server_greeting[2]) is tuple)
    assert(type(server_greeting[3]) is tuple)
    assert(all(type(i) is bytes for i in server_greeting[3]))

    ver_min, ver_max, mechs, caps = server_greeting
    if 2 not in range(ver_min, ver_max+1):
        raise SVNProtocolError('Version {0}-{1} unsupported, wanted {2}'.format(ver_min, ver_max, 2))

    client_greeting = build_reply((2, (b'edit-pipeline', b'svndiff1', b'accepts-svndiff2', b'absent-entries'), url, 'check-versions/1.0', tuple()))
    s.send(client_greeting)

    return caps

def auth(s):
    auth_request = read_response(s)
    assert(type(auth_request) is tuple)
    assert(len(auth_request) == 2)
    assert(type(auth_request[0]) is tuple)
    assert(all(type(i) is bytes for i in auth_request[0]))
    assert(type(auth_request[1]) is SVNString)

    mechs, realm = auth_request

    if b'ANONYMOUS' not in mechs:
        raise SVNProtocolError('Only ANONYMOUS auth mechanism supported: {0!r}'.format(mechs))

    auth_reply = build_reply((b'ANONYMOUS', (SVNString(base64.b64encode(b'anonymous@anonymous')), )))
    s.send(auth_reply)

    # Not a response but only a tuple
    auth_result = read_tuple(s)
    assert(type(auth_result) is tuple)
    assert(len(auth_result) == 2)
    assert(type(auth_result[0]) is bytes)
    assert(type(auth_result[1]) is tuple)

    if auth_result[0] == b'success':
        assert(len(auth_result[1]) == 0 or (len(auth_result[1]) == 1 and
            type(auth_result[1][0]) is SVNString))
        token = auth_result[1][0] if len(auth_result[1]) else None
        return True, token
    elif auth_result[0] == b'failure':
        assert(len(auth_result[1]) == 1)
        assert(type(auth_result[1][0]) is SVNString)
        return False, auth_result[1][0]
    elif auth_result[0] == b'step':
        raise SVNProtocolError('Step in authentication unsupported')
    else:
        raise SVNProtocolError('Got unknown authentication result: {0!r}'.format(auth_result[0]))

def repos_info(s):
    infos = read_response(s)
    assert(type(infos) is tuple)
    assert(len(infos) == 3)
    assert(type(infos[0]) is SVNString)
    assert(type(infos[1]) is SVNString)
    assert(type(infos[2]) is tuple)
    assert(all(type(i) is bytes for i in infos[2]))

    uuid, repo_url, caps = infos

    return uuid, repo_url, caps

def send_command(s, command):
    req = build_reply(command)
    s.send(req)

    auth_request = read_response(s)
    assert(type(auth_request) is tuple)
    assert(len(auth_request) == 2)
    assert(type(auth_request[0]) is tuple)
    assert(all(type(i) is bytes for i in auth_request[0]))
    assert(type(auth_request[1]) is SVNString)

    mechs, realm = auth_request

    if len(mechs):
        raise SVNProtocolError('Reauthentication not supported')

    return read_response(s)

def get_latest_rev(s):
    result = send_command(s, (b'get-latest-rev', tuple()))

    assert(type(result) is tuple)
    assert(len(result) == 1)
    assert(type(result[0]) is int)

    return result[0]

def check_path(s, path, rev = None):
    if rev is None:
        rev = tuple()
    else:
        rev = (rev, )
    result = send_command(s, (b'check-path', (path, rev)))

    assert(type(result) is tuple)
    assert(len(result) == 1)
    assert(type(result[0]) is bytes)

    return result[0]

def get_dir(s, path, rev = None, want_props=False, want_contents=False, dirent_fields=None):
    if rev is None:
        rev = tuple()
    else:
        rev = (rev, )
    if dirent_fields is None:
        if want_contents:
            dirent_fields = (b'kind', b'size', b'has-props', b'created-rev',
                b'time', b'last-author',b'word')
        else:
            dirent_fields = tuple()

    # We don't send want_iprops and don't expect a reply with it
    result = send_command(s, (b'get-dir', (path, rev, want_props, want_contents, dirent_fields)))

    assert(type(result) is tuple)
    assert(len(result) >= 3)
    assert(type(result[0]) is int)
    assert(type(result[1]) is tuple)
    assert(type(result[2]) is tuple)

    revision = result[0]
    props = None
    if want_props:
        assert(all(
            type(p) is tuple and
            len(p) == 2 and
            type(p[0]) is SVNString and
            type(p[1]) is SVNString for p in result[1]))
        props = dict(result[1])

    entries = None
    if want_contents:
        assert(all(type(entry) is tuple for entry in result[2]))
        entries = list(parse_dirent(entry)
                for entry in result[2])

    return revision, props, entries

def get_file(s, path, rev, want_props=False, want_contents=False):
    if rev is None:
        rev = tuple()
    else:
        rev = (rev, )

    # We don't send want_iprops and don't expect a reply with it
    result = send_command(s, (b'get-file', (path, rev, want_props, want_contents)))

    assert(type(result) is tuple)
    assert(len(result) == 3)
    assert(type(result[0]) is tuple)
    assert(len(result[0]) == 0 or (len(result[0]) == 1 and type(result[0][0]) is SVNString))
    assert(type(result[1]) is int)
    assert(type(result[2]) is tuple)

    checksum = result[0][0].decode('ascii') if len(result[0]) else None
    revision = result[1]

    props = None
    if want_props:
        assert(all(
            type(p) is tuple and
            len(p) == 2 and
            type(p[0]) is SVNString and
            type(p[1]) is SVNString for p in result[2]))
        props = dict(result[2])

    content = None
    if want_contents:
        md5 = hashlib.md5()
        content = b''
        for token in read_tokens(s):
            if type(token) is not SVNString:
                raise SVNProtocolError('Unexpected token when receiving contents: {0!r}'.format(token))
            if len(token) == 0:
                break
            content += token
            md5.update(token)
        else:
            raise SVNProtocolError('Unexpected end of stream when receiving contents')
        result = read_response(s)
        assert(type(result) is tuple and len(result) == 0)
        digest = md5.hexdigest()
        if checksum and digest != checksum:
            raise SVNProtocolError('Invalid checksum while fetching contents: {0} (expected {1})'.format(digest, checksum))

    return checksum, revision, props, content

def test():
    server = ("svn.riscos.info", 3690)
    url = 'svn://svn.riscos.info/gccsdk/tags/'
    path = ''
    s = socket.create_connection(server)

    print(greeting(s, url))
    print(auth(s))
    print(repos_info(s))
    rev = get_latest_rev(s)
    print(rev)
    kind = check_path(s, path, rev)
    print(kind)
    if kind == b'dir':
        print(get_dir(s, path, rev, True, True))
    elif kind == b'file':
        print(get_file(s, path, rev, True, True))

if __name__ == '__main__':
    test()
