extends RefCounted
## Browser device identity and input capability snapshot.
## Presentation can use this profile, while State remains the progression owner.

static var _cached: Dictionary = {}

static func snapshot() -> Dictionary:
	if not _cached.is_empty(): return _cached.duplicate(true)
	if OS.has_feature("web"):
		var raw: Variant = JavaScriptBridge.eval("""(() => {
			const ua = String(navigator.userAgent || '');
			const platform = String(navigator.userAgentData?.platform || navigator.platform || '');
			const model = String(navigator.userAgentData?.model || '');
			const maxTouchPoints = Number(navigator.maxTouchPoints || 0);
			const ipadOS = /Macintosh/i.test(ua) && maxTouchPoints > 1;
			const android = /Android/i.test(ua);
			const phone = /Android.*Mobile/i.test(ua) || /iPhone|iPod|Windows Phone/i.test(ua);
			const tablet = /iPad/i.test(ua) || ipadOS || (android && !/Mobile/i.test(ua));
			const kind = phone && !tablet ? 'phone' : tablet ? 'tablet' : 'desktop';
			const coarse = Boolean(window.matchMedia?.('(any-pointer: coarse)').matches || window.matchMedia?.('(pointer: coarse)').matches);
			const fine = Boolean(window.matchMedia?.('(any-pointer: fine)').matches || window.matchMedia?.('(pointer: fine)').matches);
			const inputProfile = coarse && fine ? 'hybrid' : coarse ? 'coarse' : fine ? 'fine' : 'unknown';
			const detectedModel = model || (kind === 'phone' ? (android ? 'Android phone' : 'iPhone') : kind === 'tablet' ? (ipadOS || /iPad/i.test(ua) ? 'iPad' : 'Android tablet') : platform || 'desktop');
			return JSON.stringify({ kind, model: detectedModel, platform, inputProfile, maxTouchPoints });
		})()""", true)
		var parsed: Variant = JSON.parse_string(str(raw))
		if parsed is Dictionary: _cached = parsed
	if _cached.is_empty():
		var platform := OS.get_name()
		_cached = {"kind":"desktop", "model":platform+" desktop", "platform":platform, "inputProfile":"unknown", "maxTouchPoints":0}
	return _cached.duplicate(true)

static func is_mobile() -> bool:
	var kind := str(snapshot().get("kind", "desktop"))
	return kind == "phone" or kind == "tablet"

static func uses_touch_controls() -> bool:
	# A desktop with a touchscreen remains a desktop input layout. The browser
	# profile marks it as hybrid without enabling the movement stick.
	return is_mobile()
