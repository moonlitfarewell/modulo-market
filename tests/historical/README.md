# Historical regression tests

These test modules are retained as milestone history and are not part of the
current release gate. They were written against earlier source layouts and
UI implementations (0.0–0.9.x). Their failures against the 0.12.x source are
not current runtime defects; many assert exact historical version strings,
function placement, tab names, or widget construction details that have since
changed. Do not delete this history or silently treat it as current acceptance.

Current release acceptance lives in the active `tests/test_*.py` suite at the
`tests/` root. If a historical behavior is still required, port its intent into
a behavior-oriented test against the current implementation before retiring
that historical module.
