# tests

Unit and system tests use [gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4), installed by
[gd-plug](https://github.com/imjp94/gd-plug) from `plug.gd`. Addons aren't committed, so after cloning, and
before opening the editor:

```sh
godot --headless -s plug.gd install
```

Then run the tests from the GdUnit panel in the editor, or headless with `tests/run.sh`. Pass a suite path to
run just that one: `tests/run.sh res://tests/test_game_settings.gd`. Reports go to `reports/`.
