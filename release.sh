#!/bin/bash
usage() { echo "Usage: $0 VERSION [OUTDIR]"; exit 1; }

[ $1 ] || usage
[ -f "$HOME/.releaserc" ] && source "$HOME/.releaserc"

OUTDIR=$2
[ $OUTDIR ] || OUTDIR=$DEF_OUTDIR
[ $OUTDIR ] || OUTDIR=.

TMPDIR=`mktemp -d`
PDIR=skema-$1
RELDIR=$TMPDIR/$PDIR

cp -r "$PWD" "$RELDIR" &&
rm -fr "$RELDIR"/.git* && # delete git stuff
rm -fr "$RELDIR"/release.sh && # delete this file
cd $TMPDIR &&
tar cvzf "$PDIR.tar.gz" "$PDIR" >/dev/null &&
mv "$PDIR.tar.gz" "$OUTDIR"
echo $OUTDIR/$PDIR.tar.gz

rm -fr "$TMPDIR"


