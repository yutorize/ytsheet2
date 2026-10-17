"""DX3 enemy regression tests. Run with: python3 tests/test_dx3_enemy.py"""
import contextlib
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest
from urllib.parse import parse_qs, urlencode, urlsplit


class EnemyRegressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temporary = tempfile.TemporaryDirectory(prefix="ytsheet-dx3-enemy-")
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.root = Path(cls.temporary.name) / "sheet"
        shutil.copytree(
            Path(__file__).resolve().parents[1],
            cls.root,
            ignore=shutil.ignore_patterns(
                ".git", "data", "config.cgi", "work", "__pycache__"
            ),
        )
        cls.config = cls.root / "dx3rd/config.cgi"
        cls.config.write_bytes(
            (cls.root / "dx3rd/config.cgi.default").read_bytes()
        )
        (cls.root / "_core/data").mkdir()
        (cls.root / "_core/data/token.cgi").touch()
        cls.clock = 1800000000
        cls.enemy_data = dict(
            type="e", enemyName="検証エネミー", enemyType="一般",
            author="Z製作者", group="npc", tags="検証タグ",
            syndrome1="キュマイラ", skillMelee="4", encroachTotal="120",
            weaponNum="3", weapon1Name="負の命中修正", weapon1Skill="白兵",
            weapon1Acc="-2", weapon1Atk="7",
            weapon2Name="正の命中修正", weapon2Skill="白兵", weapon2Acc="3",
            weapon3Name="修正なし", weapon3Skill="白兵", weapon3Acc="0",
            comboNum="1", combo1Name="検証コンボ", combo1Skill="白兵",
            combo1Condition1="常時", combo1Crit1="8",
        )
        cls.enemy = cls.create(**cls.enemy_data)
        cls.other = cls.create(
            type="e", enemyName="別エネミー", enemyType="一般",
            author="A製作者", group="pc", tags="別タグ",
        )
        cls.secret = cls.create(
            type="e", enemyName="秘匿エネミー", enemyType="一般",
            protect="password", forbidden="battle", **{"pass": "TestPass"},
            comboNum="1", combo1Name="SECRET_COMBO",
            combo1Skill="白兵", combo1Condition1="first",
            combo1Condition5="SECRET_FIFTH_CONDITION",
            combo1DiceAdd5="98761", combo1Crit5="98762",
            combo1FixedAdd5="98763", combo1Atk5="98764",
        )
        cls.pc = cls.create(characterName="検証PC", group="pc")

    @classmethod
    def request(cls, query=None, data=None):
        cls.clock += 1
        payload = urlencode(data).encode() if data is not None else b""
        env = os.environ.copy()
        env.update(
            REQUEST_METHOD="POST" if data is not None else "GET",
            QUERY_STRING=urlencode(query or {}),
            CONTENT_TYPE="application/x-www-form-urlencoded",
            CONTENT_LENGTH=str(len(payload)), SERVER_NAME="localhost",
            SERVER_PORT="8000", SERVER_PROTOCOL="HTTP/1.1",
            GATEWAY_INTERFACE="CGI/1.1", REMOTE_ADDR="127.0.0.1",
            SCRIPT_NAME="/dx3rd/index.cgi", HTTP_HOST="localhost:8000",
            HTTP_COOKIE="",
        )
        # Keep new-sheet file names distinct without waiting between requests.
        runner = (
            "BEGIN { *CORE::GLOBAL::time = sub () { "
            + str(cls.clock)
            + ' }; } require "./index.cgi";'
        )
        result = subprocess.run(
            ["perl", "-e", runner], cwd=cls.root / "dx3rd", env=env,
            input=payload, capture_output=True, timeout=30,
        )
        if result.returncode or result.stderr:
            raise AssertionError(result.stderr.decode(errors="replace"))
        headers, separator, body = result.stdout.decode().partition("\n\n")
        if not separator or "Software error:" in body:
            raise AssertionError(headers + "\n" + body[:1000])
        return body

    @classmethod
    def create(cls, **fields):
        blank = cls.request(dict(mode="blanksheet", type=fields.get("type", "")))
        token = re.search(r'name="_token" value="([^"]+)"', blank)[1]
        data = dict(
            mode="make", ver="2.01.005", _token=token,
            protect="none", paletteUseVar="1", paletteUseBuff="1",
        )
        data.update(fields)
        result = json.loads(cls.request(data=data))
        if result.get("result") != "make":
            raise AssertionError(result)
        return result["message"]

    @contextlib.contextmanager
    def settings(self, **values):
        original = self.config.read_bytes()
        extra = "\n".join(
            "$set::" + key + " = " + str(value) + ";"
            for key, value in values.items()
        )
        try:
            self.config.write_bytes(original + ("\n" + extra + "\n1;\n").encode())
            yield
        finally:
            self.config.write_bytes(original)

    def assert_enemy_link(self, page, sheet_id):
        self.assertIn('href="./?id=' + sheet_id + '"', page)

    def test_private_fifth_combo_condition_is_masked(self):
        page = self.request(dict(id=self.secret))
        self.assertIn('class="forbidden"', page)
        for secret in (
            "SECRET_COMBO", "SECRET_FIFTH_CONDITION",
            "98761", "98762", "98763", "98764",
        ):
            with self.subTest(secret=secret):
                self.assertTrue(secret not in page, secret + " leaked")
        # An unrestricted sheet must retain its combat data.
        page = self.request(dict(id=self.enemy))
        self.assertIn("検証コンボ", page)

    def test_search_form_preserves_enemy_type(self):
        page = self.request(dict(type="e"))
        form = re.search(r'<form[^>]+id="form-search".*?</form>', page, re.S)[0]
        submitted = dict(
            re.findall(r'<input type="hidden" name="([^"]+)" value="([^"]*)"', form)
        )
        submitted.update(name="検証エネミー", group="all")
        result = self.request(submitted)
        self.assertIn("エネミー一覧", result)
        self.assert_enemy_link(result, self.enemy)
        self.assertNotIn('href="./?id=' + self.other + '"', result)

    def test_sort_links_preserve_type_and_filters(self):
        page = self.request(dict(type="e", group="all", tag="検証タグ"))
        links = [
            html.unescape(link)
            for link in re.findall(r'href="([^"]+)"', page)
            if "&sort=" in link
        ]
        self.assertEqual(len(links), 3)
        for link in links:
            with self.subTest(link=link):
                query = parse_qs(urlsplit(link).query)
                self.assertEqual(query.get("type"), ["e"])
                self.assertEqual(query.get("group"), ["all"])
                self.assertEqual(query.get("tag"), ["検証タグ"])
                result = self.request({k: v[0] for k, v in query.items()})
                self.assertIn("エネミー一覧", result)
                self.assert_enemy_link(result, self.enemy)
                self.assertNotIn('href="./?id=' + self.other + '"', result)

    def test_author_search_and_sort(self):
        page = self.request(dict(type="e"))
        self.assertRegex(page, r'<input type="text" name="author"')
        result = self.request(dict(type="e", author="A製作者"))
        self.assert_enemy_link(result, self.other)
        self.assertNotIn('href="./?id=' + self.enemy + '"', result)
        result = self.request(dict(type="e", sort="pl"))
        self.assertLess(
            result.index('href="./?id=' + self.other + '"'),
            result.index('href="./?id=' + self.enemy + '"'),
        )

    def test_pagination_keeps_search_conditions(self):
        with self.settings(pagemax=1):
            page = self.request(dict(type="e", group="all", name="エネミー"))
            link = next(
                html.unescape(link)
                for link in re.findall(r'href="([^"]+)"', page)
                if "&page=2" in link
            )
            query = parse_qs(urlsplit(link).query)
            self.assertEqual(query.get("type"), ["e"])
            self.assertEqual(query.get("group"), ["all"])
            self.assertEqual(query.get("name"), ["エネミー"])
            result = self.request({k: v[0] for k, v in query.items()})
        self.assertIn("エネミー一覧", result)
        self.assert_enemy_link(result, self.other)

    def test_more_link_opens_full_enemy_list(self):
        with self.settings(list_maxline=1):
            page = self.request(dict(type="e"))
            self.assertNotIn('href="./?id=' + self.enemy + '"', page)
            link = html.unescape(
                re.search(r'<p class="more"><a href="([^"]+)"', page)[1]
            )
            query = parse_qs(urlsplit(link).query)
            self.assertEqual(query.get("type"), ["e"])
            result = self.request({k: v[0] for k, v in query.items()})
        self.assert_enemy_link(result, self.enemy)
        self.assert_enemy_link(result, self.other)

    def test_simple_list_includes_enemies(self):
        with self.settings(simplelist=1):
            page = self.request(dict(type="e"))
        self.assert_enemy_link(page, self.enemy)
        self.assert_enemy_link(page, self.other)
        self.assertIn("検証エネミー", page)
        self.assertNotIn("<table>", page)

    def test_exports_retain_names_and_custom_nameplates(self):
        fixtures = {
            "enemy": json.loads(self.request(dict(id=self.enemy, mode="json"))),
            "pc": json.loads(self.request(dict(id=self.pc, mode="json"))),
        }
        script = r"""
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
for (const file of [
  '_core/skin/_common/js/lib/ytsheetCommon.js',
  '_core/skin/dx3/js/lib/ytsheetConsts.js',
  '_core/skin/dx3/js/lib/ytsheetToCcfolia.js',
  '_core/skin/dx3/js/lib/ytsheetToUdonarium.js',
  '_core/skin/dx3/js/lib/ytsheetToText.js',
]) vm.runInThisContext(fs.readFileSync(file, 'utf8'), {filename: file});
const fixtures = JSON.parse(fs.readFileSync(0, 'utf8'));
output.getChatPalette = async () => ({palette: '', parameters: []});
(async () => {
  for (const [key, expected] of [['enemy', '検証エネミー'], ['pc', '検証PC']]) {
    const data = fixtures[key];
    const cc = JSON.parse(await output.generateCcfoliaJson('DoubleCross3PC', data));
    assert.equal(cc.data.name, expected);
    const xml = await output.generateUdonariumXml('DoubleCross3PC', data);
    assert.ok(xml.includes('<data name="name">' + expected + '</data>'));
    assert.ok(output.generateCharacterTextOfDoubleCross3PC(data).includes(expected));
    const custom = {...data, namePlate: 'コマ専用名'};
    const customCc = JSON.parse(await output.generateCcfoliaJson('DoubleCross3PC', custom));
    assert.equal(customCc.data.name, 'コマ専用名');
    const customXml = await output.generateUdonariumXml('DoubleCross3PC', custom);
    assert.ok(customXml.includes('<data name="name">コマ専用名</data>'));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
"""
        result = subprocess.run(
            ["node", "-e", script], cwd=self.root,
            input=json.dumps(fixtures).encode(), capture_output=True, timeout=30,
        )
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        page = self.request(dict(id=self.enemy))
        self.assertIn("<title>検証エネミー - ", page)

    def test_weapon_accuracy_is_applied_in_each_palette_format(self):
        for variables in ("1", "0"):
            data = dict(
                self.enemy_data, mode="save", id=self.enemy, ver="2.01.005",
                protect="none", protectOld="none",
                paletteUseVar=variables, paletteUseBuff="1",
            )
            result = json.loads(self.request(data=data))
            self.assertEqual(result["result"], "ok")
            for tool in ("", "tekey", "bcdice"):
                with self.subTest(variables=variables, tool=tool):
                    palette = self.request(dict(id=self.enemy, mode="palette", tool=tool))
                    attacks = [line for line in palette.splitlines() if "命中／" in line]
                    self.assertEqual(len(attacks), 3)
                    skill = "{白兵}" if variables == "1" else "4"
                    for line, modifier in zip(attacks, ("-2", "+3", "")):
                        self.assertIn("+" + skill + modifier + "+", line)


if __name__ == "__main__":
    unittest.main(verbosity=2)
