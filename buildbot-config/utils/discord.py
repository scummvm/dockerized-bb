import jinja2

from twisted.internet import defer

from buildbot.process.results import SUCCESS, WARNINGS, FAILURE, SKIPPED, EXCEPTION, RETRY, CANCELLED, statusToString
from buildbot.reporters.base import ReporterBase
from buildbot.reporters.generators.buildset import BuildSetStatusGenerator
from buildbot.reporters.message import MessageFormatterBase, create_context_for_build
from buildbot.util import httpclientservice

# Fix a bug in BuildStatusGeneratorMixin which misses _matches_any_tag
try:
    BuildSetStatusGenerator._matches_any_tag
except AttributeError:
    import buildbot.reporters.generators.utils
    import buildbot.reporters.generators.build
    buildbot.reporters.generators.utils.BuildStatusGeneratorMixin._matches_any_tag = buildbot.reporters.generators.build.BuildStatusGenerator._matches_any_tag

UNKNOWN_COLOR = 0xeeeeee
COLORS = {
    None: 0xe7d100,
    SUCCESS: 0x88dd44,
    WARNINGS: 0xffaa33,
    FAILURE: 0xee8888,
    SKIPPED: 0xaaddee,
    EXCEPTION: 0xcc66cc,
    RETRY: 0xeecccc,
    CANCELLED: 0xeecccc
}

UNKNOWN_EMOJI = ":grey_question:"
EMOJIS = {
    None: ":hourglass_flowing_sand:",
    SUCCESS: ":white_check_mark:",
    WARNINGS: ":warning:",
    FAILURE: ":x:",
    SKIPPED: ":track_next:",
    EXCEPTION: ":boom:",
    RETRY: ":repeat:",
    CANCELLED: ":stop_button:"
}

class DiscordFormatter(MessageFormatterBase):
    template_type = 'discord'

    compare_attrs = ['body_template', 'title_template']

    DEFAULT_CONTENT = "The buildbot has detected a **{{status_detected}}** on builder {{build['builder']['name']}}\n`{{build['state_string']}}`"
    DEFAULT_TITLE = "{{build.results_emoji}} {{summary}}"

    def __init__(self, content=None, title=None, customize=None, **kwargs):
        super().__init__(**kwargs)

        if content is None:
            content = self.DEFAULT_CONTENT
        self.body_template = jinja2.Template(content)
        if title is None:
            title = self.DEFAULT_TITLE
        self.title_template = jinja2.Template(title)
        self._customize = customize

    def render_message_body(self, context):
        build = context['build']

        results = build['results']

        embed = dict()
        embed['title'] = self.title_template.render(context)
        embed['description'] = self.body_template.render(context)
        embed['url'] = context['build_url']
        embed['color'] = COLORS.get(results, UNKNOWN_COLOR)
        embed['fields'] = []
        if context['sourcestamps']:
            embed['fields'].append({
                'name': 'Source',
                'value': context['sourcestamps'],
            })
        if context['projects'] and context['projects'] != context['buildbot_title']:
            embed['fields'].append({
                'name': 'Projects',
                'value': context['projects'],
            })
        embed['author'] = dict()
        embed['author']['name'] = build['builder']['name']
        embed['author']['url'] = context['buildbot_url']
        embed['author']['icon_url'] = '{}/img/icon.svg'.format(context['buildbot_url'])
        embed['footer'] = dict()
        embed['footer']['text'] = context['buildbot_title']
        #embed['footer']['icon_url'] = ''

        if self._customize:
            self._customize(context, embed)

        return [embed]

    @defer.inlineCallbacks
    def format_message_for_build(self, mode, buildername, build, master, blamelist):
        ctx = create_context_for_build(mode, buildername, build, master, blamelist)
        ctx['build']['results_emoji'] = EMOJIS.get(build['results'], UNKNOWN_EMOJI)
        ctx['buildbot_title'] = master.config.title
        ctx['master'] = master
        msgdict = yield self.render_message_dict(master, ctx)
        return msgdict

class DiscordStatusPush(ReporterBase):
    name = "DiscordStatusPush"
    secrets = ['webhook_url', 'token']
    compare_attrs = ['message_template']

    # Use a bold space to have a blank line before embeds
    DEFAULT_MESSAGE = "{{results_emoji}} Builds are now in state **{{results_text}}**\n** **"

    def checkConfig(self, webhook_url, token=None,
            debug=None, verify=None,
            generators=None, message=None,
            **kwargs):

        if message is None:
            message = self.DEFAULT_MESSAGE
        jinja2.Template(message)

        if generators is None:
            generators = self._create_default_generators()

        super().checkConfig(generators=generators, **kwargs)
        httpclientservice.HTTPClientService.checkAvailable(self.__class__.__name__)

    @defer.inlineCallbacks
    def reconfigService(self, webhook_url, token=None,
            debug=None, verify=None,
            generators=None, message=None,
            **kwargs):

        if token is not None:
            webhook_url = '{}/{}'.format(webhook_url, token)

        if message is None:
            message = self.DEFAULT_MESSAGE
        self.message_template = jinja2.Template(message)

        if generators is None:
            generators = self._create_default_generators()

        yield super().reconfigService(generators=generators, **kwargs)

        print([r.filter for r in self._event_consumers])

        self._http = yield httpclientservice.HTTPClientService.getService(
            self.master, webhook_url,
            debug=debug, verify=verify)

    def _create_default_generators(self):
        formatter = DiscordFormatter()
        return [
            BuildSetStatusGenerator(message_formatter=formatter)
        ]

    @defer.inlineCallbacks
    def sendMessage(self, reports):
        dl = []
        for report in reports:
            if report['type'] != 'discord':
                log.msg("DiscordStatusPush: got report of unexpected type {}".format(report['type']))
                continue

            report['results_text'] = statusToString(report['results'])
            # No color in markdown, so use emoji to be visual
            report['results_emoji'] = EMOJIS.get(report['results'], UNKNOWN_EMOJI)
            json = {}
            json['content'] = self.message_template.render(report)

            embeds = report['body']
            while len(embeds) > 0:
                # One message for a group of 10 embeds
                json['embeds'] = embeds[0:10]
                d = self._http.post("", json=json)
                dl.append(d)

                embeds = embeds[10:]

        responses = yield defer.gatherResults(dl, consumeErrors=True)
        for response in responses:
            if not (200 <= response.code < 300):
                log.msg("{}: unable to upload status: {}".format(response.code, response.content))
