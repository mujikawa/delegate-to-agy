import assert from "node:assert/strict";
import test from "node:test";

import { normalizeLineEndings } from "../src/normalize-line-endings.js";

test("normalizes CRLF and CR to LF", () => {
  assert.equal(normalizeLineEndings("a\r\nb\rc\n"), "a\nb\nc\n");
});

test("rejects non-string input", () => {
  assert.throws(() => normalizeLineEndings(null), TypeError);
});
