# When loaded, this module monkey patch IRC reporter to add SASL support
import base64

from twisted.words.protocols import irc
import buildbot.reporters.irc as brirc

class SASLIrcStatusBot(brirc.IrcStatusBot):
    def connectionMade(self):
        # Send CAP line first to avoid bans before auth
        if self.password:
            self.sendLine('CAP REQ :sasl')
        super().connectionMade()

    def irc_CAP(self, prefix, params):
        if not self.password:
            self.log('No password, CAP unexpected')
            self.sendLine('CAP END')
            return

        if (params[1] != 'ACK' or
            'sasl' not in params[-1].split()):
            self.log('No SASL support, proceeding without')
            self.sendLine('CAP END')
            return

        sasl = base64.b64encode('{0}\0{0}\0{1}'.format(
            self.nickname, self.password).encode('utf-8')).decode('ascii')
        self.sendLine('AUTHENTICATE PLAIN')
        self.sendLine('AUTHENTICATE ' + sasl)

    def irc_900(self, prefix, params):
        self.log('Logged in: {0}'.format(' '.join(params)))

    def irc_901(self, prefix, params):
        self.log('Logged out: {0}'.format(' '.join(params)))

    def irc_903(self, prefix, params):
        # Authentication is successful: let's continue
        self.log('SASL authentication succeeded: {0}'.format(' '.join(params)))
        self.sendLine('CAP END')

    def irc_904(self, prefix, params):
        self.log('SASL authentication failed: {0}'
                ', proceeding without'.format(' '.join(params)))
        self.sendLine('CAP END')
    
    irc_905 = irc_904
    irc_906 = irc_904
    irc_907 = irc_904
    irc_908 = irc_904

brirc.IrcStatusFactory.protocol = SASLIrcStatusBot
