#!/bin/sh

ROOTDIR="/"
DELMODE="warn"

Err() {
	echo "$@" | mail -s "configs2hg" admins
	logger -p user.err -t "config2hg" -s "$@"
}

Fail() { Err "$@"; exit 1; }

Doit() {
	test -n "$VERBOSE" && echo "$@"
	test -n "$DRY_RUN" || "$@"
}

while test $# != 0; do
	case "$1" in
		--trace   ) shift; set -x ;;
		--dry     ) shift; VERBOSE=1 ; DRY_RUN=1 ;;
		--verbose ) shift; VERBOSE=1 ;;
		--rootdir ) shift; test $# = 0 && Fail "missing --rootdir value"; ROOTDIR="$1"; shift ;;
		--delmode ) shift; test $# = 0 && Fail "missing --delmode value"; DELMODE="$1"; shift ;;
		-* ) Fail "wrong cmdline: $1" ;;
		* ) break ;;
	esac
done

test $# = 2 || Fail "usage: $0 filelist destdir"
FILELIST="$1"
DESTDIR="$2"

test -d "$DESTDIR/.hg"  || Fail "Missing subdir $DESTDIR/.hg"

NOT_EMPTY=
while read fn; do
	fn=${fn%%#*}                 # ..strip comments
	test "$fn" = "" && continue  # ..skip empty lines. todo!!! trim spaces???
	NOT_EMPTY=1

	# todo??? support wildcards!!!
	src="$ROOTDIR/$fn"
	dst="$DESTDIR/$fn"

	if test -e "$dst"; then
		srctype="$(LANG=C stat -c '%F' "$src" 2>/dev/null)"
		dsttype="$(LANG=C stat -c '%F' "$dst" 2>/dev/null)"
		test "$srctype" = "$dsttype" || Fail "type changed: src:$src:$srctype dst:$dst:$dsttype"
	fi

	if test -d "$src/."; then
		mkdir -p "$dst" || Fail "mkdir $dst"
		Doit rsync -auq --delete --numeric-ids "$src/" "$dst/" || Fail "rsync $src $dst"
		# todo!!! use cp instead of rsync???
	elif test -e "$src"; then
		Doit mkdir -p "$(dirname $dst)" || Fail "mkdir dirname $dst"
		Doit cp -auf "$src" "$dst" || Fail "cp $src $dst"
	else
		case "$DELMODE" in
		  stop ) Fail "missing file $src" ;;
		  skip ) ;;
		  warn ) Err  "missing file $src" ;;
		    rm ) Doit rm -rf "$dst" ;;
		     * ) Fail "wrong DELMODE value: $DELMODE" ;;
		esac
	fi
done < $FILELIST

test -z "$NOT_EMPTY" && Fail "nothing readed from $FILELIST"

cd "$DESTDIR"
hg status >/dev/null || Fail "hg status failed"
hg status | grep -q '' || exit   # ..nothing to do
hg addremove || Fail "hg addremove failed"
hg commit -m "configs2hg: autocommit at $(date '+%Y-%m-%d_%H:%M:%S')" || Fail "hg commit failed"
